# TASK-048 — Concluída (2026-08-24)

## Resumo
Modelada a entidade `Customer` para pessoa jurídica e pessoa física, com documento CPF/CNPJ validado por dígito verificador, campos comerciais que sustentam cadastro/carteira/detalhe 360/segmentação, contrato de repositório, use cases de criação, atualização, desativação e busca por id, DTO, mapper e testes unitários.

## Agentes utilizados
- flutter-senior-architect
- vestipro-sales-representative-specialist

## Arquivos criados
- `lib/features/customers/customers.dart`
- `lib/features/customers/data/dtos/customer_dto.dart`
- `lib/features/customers/data/mappers/customer_mapper.dart`
- `lib/features/customers/domain/customer_identity_validator.dart`
- `lib/features/customers/domain/entities/customer.dart`
- `lib/features/customers/domain/entities/customer.freezed.dart`
- `lib/features/customers/domain/repositories/customer_repository.dart`
- `lib/features/customers/domain/usecases/create_customer_use_case.dart`
- `lib/features/customers/domain/usecases/customer_use_case_helpers.dart`
- `lib/features/customers/domain/usecases/deactivate_customer_use_case.dart`
- `lib/features/customers/domain/usecases/get_customer_by_id_use_case.dart`
- `lib/features/customers/domain/usecases/update_customer_use_case.dart`
- `lib/features/customers/domain/value_objects/cnpj_cpf.dart`
- `lib/features/customers/domain/value_objects/customer_sensitive_field.dart`
- `lib/features/customers/domain/value_objects/customer_status.dart`
- `lib/features/customers/domain/value_objects/customer_sync_status.dart`
- `lib/features/customers/domain/value_objects/customer_type.dart`
- `test/features/customers/data/mappers/customer_mapper_test.dart`
- `test/features/customers/domain/entities/customer_test.dart`
- `test/features/customers/domain/usecases/create_customer_use_case_test.dart`
- `test/features/customers/domain/value_objects/cnpj_cpf_test.dart`
- `docs/tasks/TASK-048-modelar-customer-CONCLUIDA.md`

## Arquivos alterados
- `docs/tasks/TASKS.md`
- `lib/app/injection.config.dart`

## Arquitetura utilizada
Clean Architecture feature-first. O domínio contém entidade, value objects, contrato de repositório e use cases sem Flutter/Firebase/Drift. A camada data contém DTO e mapper desacoplados de widgets; o mapper é registrado no DI. O repositório permanece como contrato porque a persistência real será implementada nas próximas tasks de cadastro/endereço/offline.

## Regras de negócio implementadas
- `CustomerType` diferencia `legalEntity` e `individual`.
- PJ exige CNPJ válido e razão social.
- PF exige CPF válido e nome completo.
- CPF/CNPJ são normalizados, formatados e validados por dígito verificador.
- Documento é obrigatório e checado por duplicidade por organização antes da criação.
- `organizationId` e `companyId` são obrigatórios nos use cases e não são expostos como campos mutáveis da entidade.
- Classificação, potencial, segmento, canal, vendedor responsável, tags e custom fields foram modelados sem valores hardcoded.
- Mudanças sensíveis em documento e razão social são identificadas para auditoria pela camada data/backend.

## Regras Firebase implementadas
Não aplicável nesta task. Foram criados DTO e mapper preparando persistência Firestore futura, sem alterar Security Rules.

## Analytics implementado
Não aplicável. Task de domínio/dados sem fluxo de UI ou evento comercial novo.

## Crashlytics implementado
Não aplicável. Falhas são retornadas como `AppResult`/`Failure` no domínio; não há captura nova de exceção em runtime.

## Impacto offline
Entidade inclui `CustomerSyncStatus` e campos de auditoria/versionamento para sincronização futura. Não houve implementação de Drift, outbox ou carga offline nesta task.

## Impacto multi-tenant
`organizationId` e `companyId` são obrigatórios no modelo. Duplicidade de documento é escopada por organização no contrato `CustomerRepository.existsByDocument`, preservando isolamento tenant por design.

## Testes criados
- Validação de CPF/CNPJ com casos válidos, inválidos, tamanho incorreto, dígito incorreto e dígitos repetidos.
- Mapper DTO↔entidade para PJ e PF, incluindo opcionais nulos e enums inválidos.
- Use case `CreateCustomerUseCase` cobrindo sucesso, duplicidade na organização, documento incompatível com tipo e `organizationId` ausente.
- Igualdade por valor da entidade `Customer`.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .`: `Formatted 688 files (0 changed)` com exit code 0.

## Resultado do analyzer
`flutter analyze`: `No issues found!`

## Resultado dos testes
`flutter test`: 1077 testes passaram.

## Decisões técnicas
- `CustomerRepository` ficou apenas como contrato, sem implementação Firestore/Drift, porque a task pede modelagem e as tasks seguintes cuidam de cadastro e persistência.
- Use cases não foram registrados no DI nesta task para evitar dependência não registrada de `CustomerRepository`; o mapper foi registrado por não depender de implementação futura.
- `CnpjCpf` persiste o documento normalizado em dígitos e expõe formatação para apresentação.
- Helpers compartilhados de normalização evitam duplicação entre criação e atualização.

## Riscos conhecidos
- A unicidade real do documento ainda precisa ser reforçada na implementação do repositório/backend nas próximas tasks.
- Campos configuráveis de classificação/potencial foram modelados como strings, mas a origem de configuração por organização ainda será implementada.

## Pendências
- Implementar persistência real e validação backend/Firestore Rules nas tasks seguintes.
- Integrar auditoria efetiva de campos sensíveis quando o repositório/data source existir.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test`: 1077/1077 testes passaram.
- Backlog atualizado para 48 / 220.

## Commit
`feat(customers): model customer domain`

## Push
Não realizado por solicitação do lote (`sem push`).

## Hash do commit
Pendente no momento de criação deste documento; informado na resposta final da task.

## Branch
main
