# TASK-027 — Concluída (2026-08-22)

## Resumo

Modeladas as entidades `Company` e `Branch` (feature `organizations`, mesma feature de
TASK-026), permitindo que uma `Organization` configure múltiplas empresas/marcas (`Company`)
e cada `Company` configure múltiplas lojas/showrooms/unidades (`Branch`), conforme o exemplo
da seção 3.1/3.2 de `tasks.md` ("Grupo Fashion XPTO" → "Marca A"/"Marca B" → "Loja Blumenau",
"Loja Jaraguá", "Showroom São Paulo"). Implementadas as camadas de domínio, dados
(DTO/mapper/datasource Firestore/repositório) e casos de uso de criação, listagem e
atualização, seguindo exatamente os padrões já estabelecidos por `Organization` (TASK-026).

## Agentes utilizados

- `flutter-senior-architect` (único agente obrigatório da task; task é puramente de
  modelagem/arquitetura, sem UI).

## Arquivos criados

Domínio:
- `lib/features/organizations/domain/value_objects/company_status.dart`
- `lib/features/organizations/domain/value_objects/branch_status.dart`
- `lib/features/organizations/domain/value_objects/branch_type.dart`
- `lib/features/organizations/domain/value_objects/branch_address.dart` (+ `.freezed.dart` gerado)
- `lib/features/organizations/domain/entities/company.dart` (+ `.freezed.dart` gerado)
- `lib/features/organizations/domain/entities/branch.dart` (+ `.freezed.dart` gerado)
- `lib/features/organizations/domain/repositories/company_repository.dart`
- `lib/features/organizations/domain/repositories/branch_repository.dart`
- `lib/features/organizations/domain/usecases/create_company_use_case.dart`
- `lib/features/organizations/domain/usecases/list_companies_use_case.dart`
- `lib/features/organizations/domain/usecases/update_company_use_case.dart`
- `lib/features/organizations/domain/usecases/create_branch_use_case.dart`
- `lib/features/organizations/domain/usecases/list_branches_by_company_use_case.dart`
- `lib/features/organizations/domain/usecases/update_branch_use_case.dart`

Dados:
- `lib/features/organizations/data/dtos/company_dto.dart`
- `lib/features/organizations/data/dtos/branch_address_dto.dart`
- `lib/features/organizations/data/dtos/branch_dto.dart`
- `lib/features/organizations/data/mappers/company_mapper.dart`
- `lib/features/organizations/data/mappers/branch_mapper.dart`
- `lib/features/organizations/data/datasources/company_data_source.dart`
- `lib/features/organizations/data/datasources/firestore_company_data_source.dart`
- `lib/features/organizations/data/datasources/branch_data_source.dart`
- `lib/features/organizations/data/datasources/firestore_branch_data_source.dart`
- `lib/features/organizations/data/repositories/company_repository_impl.dart`
- `lib/features/organizations/data/repositories/branch_repository_impl.dart`

Testes:
- `test/features/organizations/domain/entities/company_test.dart`
- `test/features/organizations/domain/entities/branch_test.dart`
- `test/features/organizations/domain/value_objects/branch_address_test.dart`
- `test/features/organizations/domain/usecases/create_company_use_case_test.dart`
- `test/features/organizations/domain/usecases/list_companies_use_case_test.dart`
- `test/features/organizations/domain/usecases/update_company_use_case_test.dart`
- `test/features/organizations/domain/usecases/create_branch_use_case_test.dart`
- `test/features/organizations/domain/usecases/list_branches_by_company_use_case_test.dart`
- `test/features/organizations/domain/usecases/update_branch_use_case_test.dart`
- `test/features/organizations/data/dtos/company_dto_test.dart`
- `test/features/organizations/data/dtos/branch_dto_test.dart`
- `test/features/organizations/data/mappers/company_mapper_test.dart`
- `test/features/organizations/data/mappers/branch_mapper_test.dart`
- `test/features/organizations/data/repositories/company_repository_impl_test.dart`
- `test/features/organizations/data/repositories/branch_repository_impl_test.dart`

## Arquivos alterados

- `lib/features/organizations/organizations.dart` — barrel público da feature passou a
  exportar as entidades, contratos de repositório, casos de uso e value objects de `Company`
  e `Branch` (mesmo padrão já usado para `Organization`; datasources/DTOs continuam privados
  à feature).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (novos providers
  `@injectable`/`@lazySingleton`/`@LazySingleton` de `Company`/`Branch`).

## Arquitetura utilizada

Clean Architecture feature-first, idêntica ao padrão de `Organization` (TASK-026):
Presentation (ainda não existe para esta task — é modelagem pura) → Domain (entidades
`Company`/`Branch` com Freezed, value objects `CompanyStatus`/`BranchStatus`/`BranchType`/
`BranchAddress`, contratos `CompanyRepository`/`BranchRepository`, casos de uso) → Data
(DTOs, mappers, datasources Firestore, `*RepositoryImpl`).

Decisão relevante: `FirestoreCompanyDataSource` e `FirestoreBranchDataSource` compõem o
helper genérico já existente `FirestoreCollectionDataSource<T>`
(`lib/core/database/firestore_collection_data_source.dart`), em vez de reimplementar a
cadeia `cloud_firestore` do zero (como `FirestoreOrganizationDataSource` fez, por ser a raiz
do tenant, não uma subcoleção). Esta é a primeira feature a usar esse helper genérico em
produção — o padrão que ele documenta ("feature datasources compose this class") passou a
ter um consumidor real.

## Regras de negócio implementadas

- `Company.organizationId` é obrigatório e imutável: nenhum caso de uso ou método de
  repositório aceita alterá-lo após a criação (`CompanyRepository.update` não tem parâmetro
  para isso).
- `Branch.organizationId` e `Branch.companyId` são obrigatórios e imutáveis pelo mesmo motivo
  (`BranchRepository.update` idem).
- Uma `Organization` suporta N `Company` (`listByOrganization`); uma `Company` suporta N
  `Branch` (`listByCompany`), cardinalidade real testada em `company_test.dart`,
  `branch_test.dart` e nos testes de repositório (múltiplas empresas/unidades).
- Exclusão usa soft delete: `deletedAt` é campo de auditoria, nunca removido fisicamente;
  `listByOrganization`/`listByCompany` filtram `deletedAt == null` na query Firestore.
- `version` (novo campo de auditoria pedido explicitamente pela task) é incrementado
  atomicamente no Firestore via `FieldValue.increment(1)` a cada `update`, nunca calculado
  ou recebido do cliente.
- `Branch.type` modela loja/showroom/unidade (`BranchType.store/showroom/unit`); endereço é
  opcional (`Branch.address`), com `BranchAddress.validated` disponível para quem quiser
  validar/normalizar antes de persistir.
- Toda consulta de `Company`/`Branch` exige `organizationId` (e `companyId` para `Branch`)
  como parâmetro obrigatório em toda a cadeia (use case → repository → datasource →
  Firestore path), nunca uma query global entre organizações/empresas.

## Regras Firebase implementadas

- `Company` persistida em `organizations/{organizationId}/companies/{id}`; `Branch` em
  `organizations/{organizationId}/branches/{id}` (campo `companyId` na própria doc, usado
  como filtro de query em `listByCompany` — layout exatamente conforme pedido na task).
- Nenhuma Security Rule nova criada nesta task (fora de escopo — Rules chegam na TASK-030);
  a task já deixa explícito nos comentários de código que o escopo por `organizationId`
  no client é defesa em profundidade, nunca a autorização real.
- `organizationId`/`companyId` são persistidos também como campos do documento (redundantes
  com o path) para permitir que as futuras Firestore Rules os validem sem precisar
  reconstruir o path.

## Analytics implementado

Nenhum — task é modelagem de domínio/dados, sem fluxo de UI/usuário para instrumentar.

## Crashlytics implementado

Nenhum novo ponto de captura explícito; exceptions do Firestore continuam mapeadas para
`AppException`/`Failure` via `mapFirestoreExceptionToAppException`/`mapAppExceptionToFailure`
já existentes, prontas para reporte central quando a integração de Crashlytics (TASK-019)
observar essas failures na camada de apresentação.

## Impacto offline

Nenhuma mudança de comportamento offline: `Company`/`Branch` seguem o mesmo caminho direto ao
Firestore que `Organization` (sem Outbox). Documentado como risco conhecido abaixo:
administração de Company/Branch por representante em campo sem conexão ainda não passa pelo
padrão `pending -> syncing -> synced | failed | conflict` — deverá ser avaliado quando (e se)
essas entidades ganharem UI de criação/edição offline.

## Impacto multi-tenant

- Toda leitura/escrita de `Company`/`Branch` exige `organizationId` explícito em cada camada;
  `listByOrganization`/`listByCompany` nunca aceitam consulta sem esse escopo.
- Teste de repositório (`company_repository_impl_test.dart`,
  `branch_repository_impl_test.dart`) simula explicitamente duas organizações/duas empresas e
  garante que o resultado de uma listagem nunca inclui dado da outra.
- `organizationId`/`companyId` nunca são aceitos como parâmetro de atualização — apenas como
  parâmetro de roteamento (qual documento buscar), nunca como valor a ser escrito.

## Testes criados

- Entidades: igualdade por valor, `copyWith` preservando `organizationId`/`companyId`,
  múltiplas empresas por organização e múltiplas branches por empresa, valores default de
  campos opcionais (`legalName`, `taxId`, `address`).
- Value object: `BranchAddress.validated` (trim, normalização de `complement` vazio para
  `null`, erros de validação agregados por campo).
- Casos de uso: criação e listagem (delegação, trimming, validação de campos obrigatórios,
  propagação de falha); atualização cobrindo explicitamente que não há parâmetro para alterar
  `organizationId`/`companyId` (rejeição estrutural, verificada no valor retornado e na
  chamada capturada ao repositório).
- Mappers: round-trip DTO ↔ entidade cobrindo campos opcionais (`legalName`/`taxId` nulos,
  `address` nulo/preenchido, todos os valores de `BranchType`), e exceção para status/tipo
  desconhecidos.
- DTOs: parsing de payload Firestore completo e mínimo, exceção de validação para campos
  obrigatórios ausentes ou malformados, `toJson` nunca inclui `id`.
- Repositórios: sucesso, mapeamento de exceções (`AppException` e genérica), e — requisito
  explícito da task — teste dedicado de que a listagem nunca mistura dados de outra
  organização/empresa, usando um datasource mockado com múltiplos tenants.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Resultado do formatter

Sem alterações pendentes após as correções (`Formatted 317 files (0 changed)`).

## Resultado do analyzer

`No issues found!` (analisado o projeto inteiro).

## Resultado dos testes

`flutter test` (suíte completa do projeto): **530 testes, 530 passaram, 0 falharam**.
`flutter test test/features/organizations`: **108 testes, 108 passaram** (isolado).

## Decisões técnicas

- `FirestoreCompanyDataSource`/`FirestoreBranchDataSource` compõem
  `FirestoreCollectionDataSource<T>` em vez de reimplementar a cadeia Firestore — reduz
  duplicação e é o uso pretendido pelo helper (primeiro consumidor real dele no repositório).
- Acrescentados `UpdateCompanyUseCase`/`UpdateBranchUseCase`, além dos quatro casos de uso
  explicitamente listados na task (`Create`/`List`), porque o escopo técnico da task também
  pede o método `update` no contrato de repositório e um teste explícito de rejeição de
  alteração de `organizationId`/`companyId` "pelo caso de uso" — sem esses casos de uso essa
  garantia só existiria em nível de repositório, não de caso de uso.
- `version` (`int`) modelado como campo de auditoria incremental atômico
  (`FieldValue.increment(1)`) em vez de recebido do cliente, evitando que uma corrida de
  atualizações concorrentes sobrescreva a versão.
- IDs de `Company`/`Branch` são gerados pelo chamador (mesmo padrão de
  `CreateOrganizationUseCase`), não pelo caso de uso — mantém simetria com o padrão existente
  em vez de introduzir uma dependência de geração de UUID dentro do caso de uso.
- `CompanyDto`/`BranchDto` sempre persistem `organizationId` (e `companyId`, no caso de
  `Branch`) como campo do documento, redundante com o path — necessário para que Firestore
  Rules (TASK-030) e a query `listByCompany` (filtro por `companyId`) funcionem sem depender
  de reconstruir o path a partir do documento.

## Riscos conhecidos

- `create()` de `Company`/`Branch` não é idempotente como o de `Organization`: como o `id` é
  gerado uma vez pelo chamador e a escrita no Firestore usa `set()` sem transação, um retry de
  rede após um create já bem-sucedido pode sobrescrever o documento (se o retry reusar o mesmo
  `id` e os mesmos dados, o resultado final é o mesmo; mas se o `id` mudar entre tentativas,
  cria-se um documento duplicado). A task não pede idempotência explícita para estas entidades
  (diferente de `Organization`, que documenta esse requisito para o fluxo de onboarding); se
  uma tela de criação de Company/Branch precisar de retry seguro, recomenda-se revisitar este
  ponto (ex.: transação condicional como em `FirestoreOrganizationDataSource.create`).
- `FirestoreCompanyDataSource`/`FirestoreBranchDataSource` não têm teste unitário mockando
  diretamente a cadeia do SDK `cloud_firestore` (`.collection().doc().collection()
  .withConverter()`) — mocká-la via `mocktail` seria frágil sem `fake_cloud_firestore`
  (dependência não presente no projeto). A cobertura de risco real vem de: testes de
  DTO/serialização, testes de mapper, testes de repositório (com datasource mockado na
  interface) e do fato de `FirestoreCollectionDataSource` já ser código compartilhado testado
  indiretamente (`firestore_page_slice_test.dart`, `firestore_converter_test.dart`,
  `firestore_exception_mapper_test.dart`). Recomenda-se avaliar `fake_cloud_firestore` (ou
  testes via Firebase Emulator) em uma task futura de infraestrutura de testes, não apenas
  para esta feature.
- Ainda não há Firestore Security Rules para `companies`/`branches` (chega na TASK-030) —
  hoje o isolamento multi-tenant depende inteiramente do client sempre passar o
  `organizationId` correto; documentado no código como "defesa em profundidade apenas".

## Pendências

- Nenhuma pendência dentro do escopo desta task. UI de administração de Company/Branch,
  Security Rules dedicadas e RBAC ficam para as tasks seguintes (TASK-028 a TASK-030+),
  conforme a ordem do backlog.

## Evidências

- `flutter analyze` (projeto completo): `No issues found!`
- `flutter test` (projeto completo): `+530: All tests passed!`
- `dart format --set-exit-if-changed lib test`: `Formatted 317 files (0 changed)`

## Commit

Único commit cobrindo implementação + testes + documentação + atualização do backlog.

## Push

Sim, `git push origin main` executado após o commit.

## Hash do commit

`e56a349`

## Branch

`main`
