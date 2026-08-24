# TASK-064 — Concluída (2026-08-24)

## Resumo
Modelada a entidade de domínio `Product` (EPIC-08 — Produtos e Catálogo Base): SKU, referência,
nome, descrições, marca, coleção, estação, linha, categoria, subcategoria, gênero, público, tecido,
composição, fornecedor, NCM, EAN, tags, status, data de lançamento, referências de fotos/vídeos e
suporte a atributos personalizados por organização (`ProductCustomFieldDefinition` +
`ProductCustomFieldValue`). Foram criados os value objects `Sku` e `Ean` (com checksum EAN-13/EAN-8),
os enums `ProductStatus`, `ProductGender`, `TargetAudience`, `ProductCustomFieldType` e
`ProductSyncStatus`, o DTO/mapper Firestore (`ProductDto`/`ProductMapper`) e o único caso de uso
pedido pela task: `GetProductByIdUseCase`. `ProductRepository` ficou como contrato, sem
implementação Firestore/Drift/SharedPreferences, no mesmo padrão de `LeadRepository` (TASK-055) e
`CustomerRepository` (TASK-048): a task pede modelagem de leitura básica, a persistência e o
cadastro completo ficam para TASK-065.

## Agentes utilizados
- `flutter-senior-architect` (arquitetura de domínio/dados, value objects, Firestore DTO, DI)

Não foi necessário o agente de negócio: a task é puramente de modelagem técnica (domínio/dados sem
UI), e o vocabulário funcional (seção 7 de `tasks.md`) já estava totalmente descrito no próprio
arquivo `TASK-064-modelar-product.md`.

## Arquivos criados
- `lib/features/products/products.dart`
- `lib/features/products/domain/entities/product.dart`
- `lib/features/products/domain/entities/product.freezed.dart`
- `lib/features/products/domain/entities/product_custom_field_definition.dart`
- `lib/features/products/domain/entities/product_custom_field_definition.freezed.dart`
- `lib/features/products/domain/entities/product_custom_field_value.dart`
- `lib/features/products/domain/entities/product_custom_field_value.freezed.dart`
- `lib/features/products/domain/value_objects/sku.dart`
- `lib/features/products/domain/value_objects/ean.dart`
- `lib/features/products/domain/value_objects/product_status.dart`
- `lib/features/products/domain/value_objects/product_gender.dart`
- `lib/features/products/domain/value_objects/target_audience.dart`
- `lib/features/products/domain/value_objects/product_sync_status.dart`
- `lib/features/products/domain/value_objects/product_custom_field_type.dart`
- `lib/features/products/domain/repositories/product_repository.dart`
- `lib/features/products/domain/usecases/get_product_by_id_use_case.dart`
- `lib/features/products/data/dtos/product_dto.dart`
- `lib/features/products/data/dtos/product_custom_field_definition_dto.dart`
- `lib/features/products/data/mappers/product_mapper.dart`
- `test/features/products/domain/value_objects/sku_test.dart`
- `test/features/products/domain/value_objects/ean_test.dart`
- `test/features/products/domain/entities/product_test.dart`
- `test/features/products/data/mappers/product_mapper_test.dart`
- `test/features/products/domain/usecases/get_product_by_id_use_case_test.dart`
- `docs/tasks/TASK-064-modelar-product-CONCLUIDA.md`

## Arquivos alterados
- `docs/tasks/TASKS.md` (checkbox da TASK-064 e progresso 63 → 64)
- `lib/app/injection.config.dart` (registro de `ProductMapper` como `lazySingleton`, regenerado pelo
  `build_runner`)

## Arquitetura utilizada
Clean Architecture feature-first. O domínio (`lib/features/products/domain`) não depende de
Flutter/Firebase/Drift: entidade `Product` (`freezed`, imutável, igualdade por valor), value objects
`Sku`/`Ean` com validação de formato, enums fechados do vocabulário de moda e um contrato de
repositório puro. A camada `data` contém `ProductDto`/`ProductCustomFieldDefinitionDto` (shape
Firestore, hand-rolled com `fromJson`/`toJson`, no mesmo padrão de `CustomerDto`/`LeadDto` — não foi
usado `json_serializable`/`build_runner` para os DTOs porque nenhuma outra feature do repositório
usa esse padrão; manter DTOs manuais evita introduzir uma convenção nova e inconsistente) e
`ProductMapper` (`@lazySingleton`, sem depender de `ProductRepository`). `GetProductByIdUseCase`
recebe `ProductRepository` via injeção de construtor sem `@injectable`, porque não há implementação
concreta registrada ainda (mesmo critério de `LeadRepository` na TASK-055).

## Regras de negócio implementadas
- `Product` exige `organizationId` (nunca aceito de input externo — resolvido pela sessão
  autenticada pelo chamador); `companyId` é opcional, pois algumas organizações compartilham um
  catálogo único entre empresas.
- `Sku.parse` normaliza para caixa alta e valida formato (2 a 40 caracteres, letras/números/`-`/`_`,
  sem separador nas pontas ou duplicado), lançando `ValidationException` tipada — nunca uma exceção
  crua — em qualquer formato inválido. A unicidade por organização é responsabilidade do backend; o
  value object garante apenas o formato.
- `Ean.parse` normaliza dígitos e valida comprimento (8 ou 13) e dígito verificador pelo algoritmo
  GS1 (pesos alternados 3/1 a partir do dígito adjacente ao check digit, válido tanto para EAN-13
  quanto EAN-8 por serem GTINs alinhados à direita), lançando `ValidationException` tipada em
  formato/checksum inválido.
- `Product.ean` é opcional: um produto pode não ter EAN próprio quando o código vive na cor/variante
  (regra explícita da task), enquanto `Product.sku`/`Product.reference` são exigidos no nível do
  produto.
- `ProductCustomFieldDefinition`/`ProductCustomFieldValue` modelam atributos personalizados por
  organização (tipo texto/número/booleano/lista, obrigatoriedade, `organizationId`), vinculados ao
  produto por `fieldDefinitionId` — nunca compartilhados entre tenants.
- `GetProductByIdUseCase` valida `organizationId`/`id` não vazios (trim) antes de tocar o
  repositório, retornando `ValidationFailure` tipada em payload inválido.

## Regras Firebase implementadas
Não aplicável nesta task. `ProductDto`/`ProductCustomFieldDefinitionDto` já modelam o formato de
documento Firestore (Timestamp, `organizationId` duplicado para Security Rules) para uso futuro, mas
nenhuma Security Rule ou implementação de repositório Firestore foi criada.

## Analytics implementado
Não aplicável. Task de domínio/dados sem fluxo de UI ou evento comercial novo.

## Crashlytics implementado
Não aplicável. Falhas de parsing (`Sku`/`Ean`/mapper) são exceções tipadas (`ValidationException`)
destinadas a ser convertidas em `Failure` pelo limite da camada de dados
(`mapAppExceptionToFailure`), assim como `CnpjCpf`/`Cep` em `customers`; não há captura nova de
exceção em runtime.

## Impacto offline
Entidade inclui `ProductSyncStatus` e campos de auditoria/versionamento (`version`,
`updatedAt`/`updatedBy`, `deletedAt`) preparando sincronização futura, no mesmo padrão de
`Customer`/`Lead`. Nenhuma implementação de Drift, outbox ou carga offline foi criada para Product
nesta task.

## Impacto multi-tenant
`organizationId` é obrigatório e imutável em `Product` e em `ProductCustomFieldDefinition`. O
contrato `ProductRepository.getById` é escopado por organização, e o teste do caso de uso usa um
repositório fake com chave composta (`organizationId:id`) para comprovar que uma consulta com a
organização errada falha com `NotFoundFailure` em vez de expor o produto de outro tenant.

## Testes criados
- `Sku`: normalização (trim + upper case), formatos válidos (letras/números/`-`/`_`), rejeição de
  vazio, comprimento fora de 2–40, separador nas pontas/duplicado, caracteres fora do alfabeto e
  igualdade por valor normalizado.
- `Ean`: parsing de EAN-13 (`4006381333931`) e EAN-8 (`40170725`) válidos verificados manualmente
  pelo algoritmo GS1, normalização de separadores, rejeição de checksum incorreto em ambos os
  formatos, rejeição de comprimento inválido e igualdade por dígitos.
- `Product`/`ProductCustomFieldDefinition`: igualdade por valor (`freezed`), diferença por campo
  escalar e por lista (`tags`), ausência de EAN por padrão, e custom field value vinculado por
  `fieldDefinitionId`.
- `ProductMapper`: `toEntity`/`toDto` round-trip para produto totalmente preenchido e para produto
  mínimo (campos nulos, listas vazias, sem atributos personalizados), falha tipada para
  status/gênero/sync status desconhecidos, e round-trip do mapeamento de
  `ProductCustomFieldDefinition`.
- `GetProductByIdUseCase`: sucesso, produto não encontrado, tentativa de acesso a produto de outra
  organização (deve falhar com `NotFoundFailure`, via repositório fake com chave composta por
  tenant) e validação de `organizationId`/`id` vazios sem tocar o repositório.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format lib/features/products test/features/products`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test/features/products`
- `flutter test` (suíte completa)

## Resultado do formatter
`dart format --set-exit-if-changed .`: sem alterações pendentes após a formatação inicial dos
arquivos novos (exit code 0).

## Resultado do analyzer
`flutter analyze`: `No issues found!` (13.8s).

## Resultado dos testes
- `flutter test test/features/products`: `All tests passed!` — 32 testes novos.
- `flutter test` (suíte completa): `All tests passed!` — 1350 testes, incluindo o grafo de DI
  (`test/app/injection_test.dart`, que continua resolvendo após o registro de `ProductMapper`).

## Decisões técnicas (registradas por não estarem 100% explícitas no texto da task)
- Campos da entidade usam nomes em inglês (`sku`, `reference`, `name`, `shortDescription`, ...) em
  vez dos nomes em português citados literalmente na task, para manter consistência com todo o
  restante do domínio (`Lead`, `Customer`, `Opportunity` já usam nomes em inglês apesar do
  vocabulário de negócio ser em português).
- `ProductDto`/`ProductCustomFieldDefinitionDto` foram implementados como classes manuais com
  `fromJson`/`toJson` (mesmo padrão de `CustomerDto`/`LeadDto`), e não com `json_serializable` como
  a task sugere literalmente — nenhuma outra DTO do repositório usa anotação `@JsonSerializable`
  hoje, então introduzir esse padrão isoladamente para `Product` duplicaria convenções sem
  necessidade.
- `Sku`/`Ean` lançam `ValidationException` tipada (como `CnpjCpf`/`Cep` em `customers`) em vez de
  retornar um `AppResult`/`Failure` síncrono diretamente: nenhum value object do repositório hoje
  devolve `Failure` de forma síncrona, e o limite de conversão para `Failure` já existe em
  `mapAppExceptionToFailure`. Isso cumpre "nunca exceção crua" mantendo o mesmo padrão arquitetural
  já estabelecido, em vez de criar uma convenção nova e divergente para apenas uma feature.
- A regra de completude para `ProductStatus.active` (nome, SKU e categoria mínimos, citada em
  "Regras de negócio e restrições" da task) foi deliberadamente **não** implementada nesta task: a
  própria task delimita o escopo técnico a "apenas casos de uso de leitura básica (buscar produto
  por id)" e diz explicitamente que "cadastro completo fica para TASK-065" — é lá que existirão os
  casos de uso de criação/atualização onde essa validação de negócio deve viver (nunca na entidade
  nem na UI, conforme a própria regra pede).
- `ProductRepository` foi deixado apenas como contrato (`getById`), sem implementação
  Firestore/Drift/SharedPreferences, replicando a decisão de TASK-055 para `LeadRepository` e de
  TASK-048 para `CustomerRepository`.
- `ProductCustomFieldValue.value` foi tipado como `Object?` (texto/número/booleano/lista) seguindo o
  mesmo padrão de `Customer.customFields` (`Map<String, Object?>`); a igualdade gerada pelo
  `freezed` usa comparação profunda apenas quando o tipo declarado do campo é uma coleção
  (`List`/`Map`/`Set`), então um valor de atributo do tipo lista guardado dentro de `Object?` pode
  não comparar por valor profundo — a mesma limitação que já existe hoje em
  `Customer.customFields`. Ver Riscos conhecidos.

## Riscos conhecidos
- `ProductCustomFieldValue.value` (`Object?`) não recebe igualdade profunda automática do `freezed`
  quando o valor real é uma `List<String>` (atributo do tipo `list`); dois `ProductCustomFieldValue`
  com a mesma lista de conteúdo podem comparar como diferentes hoje. É uma limitação pré-existente
  no mesmo padrão de `Customer.customFields`, não uma regressão introduzida por esta task.
- `ProductRepository` não tem implementação: nenhuma feature ainda pode buscar um `Product` real
  (Firestore/Drift/cache local). `GetProductByIdUseCase` está pronto para ser conectado a uma
  implementação futura sem alterar sua assinatura.
- `ProductCustomFieldDefinition` tem DTO/mapper, mas nenhum repositório/caso de uso de administração
  (criar/editar/listar definições por organização) — não estava no escopo de "apenas modelar" desta
  task; deve ser resolvido quando a UI de cadastro (TASK-065) ou uma task futura de configuração de
  atributos precisar persistir definições.

## Pendências
- Implementar `ProductRepository` (Firestore e/ou local) e os casos de uso de
  criação/edição/completude de status `active` na TASK-065.
- Modelar cores (TASK: coleções/estações já cobertas por `collectionId`/`seasonId` como referência
  simples; a entidade `Color`/variante em si é escopo de tasks futuras de EPIC-08, seção 7.1/7.2 de
  `tasks.md`).
- Definir onde/como `ProductCustomFieldDefinition` será administrado (CRUD por organização) quando
  a task correspondente existir no backlog.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test`: 1350/1350 testes passaram (32 novos de `products`).
- Backlog atualizado para 64 / 206.

## Commit
`feat(products): model product domain with sku and ean value objects`

## Push
Não realizado — autorizado apenas commit local nesta rodada.

## Hash do commit
Informado na resposta final da task, após a criação do commit.

## Branch
main
