# Firestore — Acesso a Dados e Modelo Inicial de Collections

Convenções de acesso ao Cloud Firestore (TASK-013), complementares às de
[`README.md`](README.md). Nenhuma UI ou camada `domain/` pode importar
`cloud_firestore` diretamente — todo acesso passa por
`lib/core/database/FirestoreCollectionDataSource<T>` (`data/datasources/`).

## Base genérica (`lib/core/database/`)

- `FirestoreCollectionDataSource<T>`: acesso a uma collection tenant-scoped
  (`organizations/{organizationId}/{collectionName}`). Toda operação exige
  `organizationId` explicitamente — nunca é possível montar uma query "global"
  esquecendo o filtro de tenant. Isso é apenas defesa em profundidade: quem
  garante isolamento de tenant de fato são as Firestore Security Rules
  (TASK-030), nunca a query do cliente.
- `FirestoreConverter<T>`: par `fromJson`/`toJson` padronizado por entidade,
  usado para montar o `withConverter` do SDK. Cada feature delega esse
  `fromJson`/`toJson` ao DTO/mapper já definidos pela convenção da TASK-004 —
  o `Map<String, dynamic>` bruto do documento nunca atravessa a fronteira de
  `data/`.
- `firestore_exception_mapper.dart`: converte `FirebaseException` do
  `cloud_firestore` para a hierarquia `AppException`/`Failure` já existente
  (`lib/core/errors/`), sem criar novos tipos:

  | Código Firestore | `AppException` | `Failure` |
  |---|---|---|
  | `unauthenticated` | `UnauthorizedException` | `AuthenticationFailure` |
  | `permission-denied` | `ForbiddenException` | `PermissionFailure` |
  | `not-found` | `NotFoundException` | `NotFoundFailure` |
  | `already-exists`, `aborted`, `failed-precondition` | `ConflictException` | `ConflictFailure` |
  | `unavailable`, `deadline-exceeded`, `cancelled` | `NetworkException` | `ConnectivityFailure` |
  | `resource-exhausted` | `ServerException` | `ServerFailure` |
  | `invalid-argument`, `out-of-range` | `ValidationException` | `ValidationFailure` |
  | outro código | `UnknownException` | `UnexpectedFailure` |

- `sliceFetchedPage`/`FirestoreQueryPage<T>`: paginação por cursor
  (`startAfterDocument`). `getPage` sempre busca `limit + 1` documentos para
  saber se há próxima página sem uma query de contagem separada; nunca é
  permitido buscar uma collection inteira de uma vez.
- `configureFirestore`: habilita `Settings(persistenceEnabled: true)` e, fora
  do flavor `prod`, conecta ao Firestore Emulator (mesmo padrão de
  `FirebaseAuthDataSource`/TASK-012). Registrado como `FirebaseFirestore`
  `@lazySingleton` em `lib/app/injection_module.dart` — só executa quando algo
  de fato resolve uma dependência que usa Firestore.

## Como uma feature usa a base

```dart
final customerConverter = FirestoreConverter<CustomerDto>(
  fromJson: CustomerDto.fromJson,
  toJson: (dto) => dto.toJson(),
);

final customersDataSource = FirestoreCollectionDataSource<CustomerDto>(
  firestore: getIt<FirebaseFirestore>(),
  collectionName: 'customers',
  converter: customerConverter,
);

final page = await customersDataSource.getPage(
  organizationId: organizationId,
  limit: 20,
  queryBuilder: (query) => query
      .where('companyId', isEqualTo: companyId)
      .where('deletedAt', isNull: true)
      .orderBy('name'),
);
```

O repositório da feature (camada `data/repositories/`) mapeia o DTO retornado
para a entidade de domínio e converte `AppException` em `Failure`, exatamente
como `AboutAppRepositoryImpl`/`AuthRepositoryImpl` já fazem hoje.

## Modelo inicial de collections

Raiz de todo tenant: `organizations/{organizationId}`. Levantamento
conceitual da seção 20 de `tasks.md` (raiz do projeto) — sujeito a revisão
por cada task de modelagem futura conforme padrão real de consultas, custo de
leitura, limites do Firestore, índices e volume; nunca criar subcollection
apenas por organização visual:

```text
organizations/{organizationId}
organizations/{organizationId}/companies/{companyId}
organizations/{organizationId}/branches/{branchId}
organizations/{organizationId}/members/{userId}
organizations/{organizationId}/teams/{teamId}
organizations/{organizationId}/roles/{roleId}
organizations/{organizationId}/customers/{customerId}
organizations/{organizationId}/leads/{leadId}
organizations/{organizationId}/opportunities/{opportunityId}
organizations/{organizationId}/activities/{activityId}
organizations/{organizationId}/products/{productId}
organizations/{organizationId}/products/{productId}/colors/{colorId}
organizations/{organizationId}/products/{productId}/variants/{variantId}
organizations/{organizationId}/sizeGrids/{gridId}
organizations/{organizationId}/collections/{collectionId}
organizations/{organizationId}/priceLists/{priceListId}
organizations/{organizationId}/warehouses/{warehouseId}
organizations/{organizationId}/inventory/{inventoryId}
organizations/{organizationId}/commercialPacks/{packId}
organizations/{organizationId}/lineSheets/{lineSheetId}
organizations/{organizationId}/preBookPrograms/{programId}
organizations/{organizationId}/orders/{orderId}
organizations/{organizationId}/backorders/{backorderId}
organizations/{organizationId}/buyerCollaborations/{sessionId}
organizations/{organizationId}/creditProfiles/{customerId}
organizations/{organizationId}/receivables/{receivableId}
organizations/{organizationId}/shipments/{shipmentId}
organizations/{organizationId}/sampleKits/{sampleKitId}
organizations/{organizationId}/territories/{territoryId}
organizations/{organizationId}/sellOutEvents/{eventId}
organizations/{organizationId}/dataQualityIssues/{issueId}
organizations/{organizationId}/targets/{targetId}
organizations/{organizationId}/insights/{insightId}
organizations/{organizationId}/savedReports/{reportId}
organizations/{organizationId}/notifications/{notificationId}
organizations/{organizationId}/auditLogs/{logId}
```

## Padrão de entidade (campos de auditoria)

Seção 21 de `tasks.md`: todo documento de negócio segue

```text
id, organizationId, companyId, status,
createdAt, createdBy, updatedAt, updatedBy, deletedAt, version
```

preenchidos no backend sempre que possível. `deletedAt` é a única forma de
"remoção": documentos de negócio nunca são fisicamente excluídos — ver
`FirestoreCollectionDataSource.softDelete`. Toda query de listagem deve
filtrar `deletedAt` (ex.: `where('deletedAt', isNull: true)`) por padrão.

## Persistência nativa do Firestore x Drift/Outbox (EPIC-14)

`configureFirestore` habilita `Settings(persistenceEnabled: true)`: um cache
gerenciado pelo próprio SDK, por listener, "best effort" — não garante que
todo o catálogo esteja disponível offline, não tem tela de resolução de
conflito, nem fila explícita de operações pendentes.

O banco local Drift + Outbox do EPIC-14 é a camada deliberada de
offline-first: carga inicial completa e controlada, fila de operações
pendentes (Outbox), motor de sincronização incremental e resolução de
conflito com UI própria. As duas camadas são complementares, não
substitutas: a persistência nativa do Firestore acelera leituras
reativas enquanto o app está online/intermitente; Drift/Outbox é quem garante
o comportamento offline-first real exigido pelo produto.

## Firestore Security Rules (estado atual)

`firestore.rules` está propositalmente em **deny-all**
(`allow read, write: if false`) até a TASK-030 implementar RBAC e isolamento
multi-tenant reais — ver comentário no próprio arquivo. Isso significa que,
hoje, qualquer chamada real ao Firestore Emulator (inclusive as deste
datasource) retorna `permission-denied`, mapeado para `ForbiddenException`;
o teste de integração desta task valida exatamente esse comportamento real,
em vez de simular regras que ainda não existem.

## Firestore Emulator

```bash
firebase emulators:start --only firestore --project vestipro
```

Host/porta ficam em `lib/core/environment/firebase_emulator_host.dart` e
`firebase_emulator_ports.dart` (compartilhados com Auth/Storage/Functions).
