# TASK-055 — Concluída (2026-08-24)

## Resumo
Modelada a entidade `Lead`, porta de entrada do funil comercial (EPIC-07/CRM): origem configurável (`LeadSource`), responsável, score numérico, máquina de estados de qualificação (`LeadStatus`) e os casos de uso `CreateLead`, `MarkLeadContacted`, `QualifyLead`, `DisqualifyLead` (com motivo obrigatório), `ConvertLeadToCustomer` e `ConvertLeadToOpportunity`. A conversão para Customer reaproveita `CreateCustomerUseCase` (TASK-048) e adiciona o campo `Customer.sourceLeadId` para preservar a rastreabilidade da origem. `LeadRepository` ficou como contrato, sem implementação Firestore/Drift, no mesmo padrão de TASK-048.

## Agentes utilizados
- flutter-senior-architect
- vestipro-sales-representative-specialist (leitura do contexto de negócio de CRM/funil em `tasks.md`, seção EPIC-07)

## Arquivos criados
- `lib/features/leads/leads.dart`
- `lib/features/leads/domain/entities/lead.dart`
- `lib/features/leads/domain/entities/lead.freezed.dart`
- `lib/features/leads/domain/lead_status_transition_rules.dart`
- `lib/features/leads/domain/repositories/lead_repository.dart`
- `lib/features/leads/domain/value_objects/lead_source.dart`
- `lib/features/leads/domain/value_objects/lead_status.dart`
- `lib/features/leads/domain/value_objects/lead_sync_status.dart`
- `lib/features/leads/domain/usecases/lead_use_case_helpers.dart`
- `lib/features/leads/domain/usecases/create_lead_use_case.dart`
- `lib/features/leads/domain/usecases/mark_lead_contacted_use_case.dart`
- `lib/features/leads/domain/usecases/qualify_lead_use_case.dart`
- `lib/features/leads/domain/usecases/disqualify_lead_use_case.dart`
- `lib/features/leads/domain/usecases/convert_lead_to_customer_use_case.dart`
- `lib/features/leads/domain/usecases/convert_lead_to_opportunity_use_case.dart`
- `lib/features/leads/data/dtos/lead_dto.dart`
- `lib/features/leads/data/mappers/lead_mapper.dart`
- `test/features/leads/domain/entities/lead_test.dart`
- `test/features/leads/domain/usecases/create_lead_use_case_test.dart`
- `test/features/leads/domain/usecases/mark_lead_contacted_use_case_test.dart`
- `test/features/leads/domain/usecases/qualify_lead_use_case_test.dart`
- `test/features/leads/domain/usecases/disqualify_lead_use_case_test.dart`
- `test/features/leads/domain/usecases/convert_lead_to_customer_use_case_test.dart`
- `test/features/leads/domain/usecases/convert_lead_to_opportunity_use_case_test.dart`
- `test/features/leads/data/mappers/lead_mapper_test.dart`
- `docs/tasks/TASK-055-modelar-lead-CONCLUIDA.md`

## Arquivos alterados
- `docs/tasks/TASKS.md` (checkbox da TASK-055 e progresso 54 → 55)
- `lib/features/customers/domain/entities/customer.dart` (campo opcional `sourceLeadId`)
- `lib/features/customers/domain/entities/customer.freezed.dart` (regenerado pelo build_runner)
- `lib/features/customers/data/dtos/customer_dto.dart` (campo opcional `sourceLeadId` em `fromJson`/`toJson`)
- `lib/features/customers/data/mappers/customer_mapper.dart` (repassa `sourceLeadId` nos dois sentidos)
- `lib/features/customers/domain/usecases/create_customer_use_case.dart` (parâmetro opcional `sourceLeadId`)
- `lib/app/injection.config.dart` (registro de `LeadMapper`, regenerado pelo build_runner)

## Arquitetura utilizada
Clean Architecture feature-first. O domínio (`lib/features/leads/domain`) não depende de Flutter/Firebase/Drift: entidade `freezed`, value objects, contrato de repositório e use cases puros. A camada `data` contém DTO e mapper (`LeadMapper`, registrado no DI como `@lazySingleton`, sem depender de `LeadRepository`) preparando a futura persistência Firestore. Os use cases de conversão/qualificação recebem `LeadRepository` via injeção de construtor (sem `@injectable`, pois não há implementação registrada ainda — mesmo critério de TASK-048). `ConvertLeadToCustomerUseCase` compõe a feature `customers` (import de `lib/features/customers/customers.dart`) reaproveitando `CreateCustomerUseCase` em vez de duplicar suas regras de validação/duplicidade de documento.

## Regras de negócio implementadas
- `Lead` exige `organizationId` (nunca aceito de input externo — resolvido pela sessão autenticada pelo chamador) e `responsibleUserId`; `companyId` e `document` são opcionais.
- `LeadSource` é configurável por organização: valores padrão (indicação, evento, site, redes sociais, prospecção ativa, outro) mais suporte a códigos customizados via `LeadSource.custom`, no mesmo padrão de `CustomerAddressType`.
- Máquina de estados (`isValidLeadStatusTransition`): `newLead -> {contacted, disqualified}`, `contacted -> {qualified, disqualified}`, `qualified -> {converted}`; `disqualified` e `converted` são terminais. Isso bloqueia explicitamente `disqualified -> converted` e qualquer transição de saída de um lead já convertido/desqualificado.
- `DisqualifyLeadUseCase` exige motivo não vazio (falha com `ValidationFailure` sem tocar o repositório quando o motivo está ausente).
- `ConvertLeadToCustomerUseCase`/`ConvertLeadToOpportunityUseCase` só permitem a conversão quando `Lead.canTransitionTo(LeadStatus.converted)` é verdadeiro (ou seja, o lead está `qualified`), e a conversão é irreversível: o `Lead` resultante fica com `status = converted`, `convertedAt` preenchido e o vínculo (`convertedCustomerId`/`convertedOpportunityId`) preservado.
- `Customer.sourceLeadId` (novo campo opcional) é preenchido pela conversão para rastrear a origem do cliente a partir do lead, sem quebrar nenhum construtor existente de `Customer`.
- Score é modelado como campo numérico simples (`Lead.score`, default 0), atribuído no `CreateLeadUseCase`; o algoritmo de scoring fica para reaproveitamento futuro (TASK-062), conforme a task pede.

## Decisões técnicas (registradas por não estarem 100% explícitas no texto da task)
- `Opportunity` ainda não existe (TASK-057 é a próxima task do backlog). Por isso `ConvertLeadToOpportunityUseCase` não cria o agregado `Opportunity`; ele recebe um `opportunityId` já gerado pelo chamador e apenas registra a transição/vínculo do lado do `Lead`. Quando TASK-057 modelar `Opportunity` (com seu próprio `sourceLeadId`, espelhando `Customer.sourceLeadId`), o fluxo de criação real da Opportunity deve ser orquestrado ali.
- Foi adicionado `MarkLeadContactedUseCase`, não listado literalmente na seção "Escopo técnico" da task, porque sem ele o status `LeadStatus.contacted` — exigido pelos testes de transição e pelo enum em si — seria inalcançável por qualquer caso de uso. É um caso de uso mínimo, coerente com "os casos de uso de qualificação" citados no objetivo da task.
- `LeadRepository` foi deixado apenas como contrato (sem implementação Firestore/Drift/SharedPreferences), replicando exatamente a decisão de TASK-048 para `CustomerRepository`: a task pede modelagem, a persistência fica para as próximas tasks (TASK-056 em diante).
- `Customer.sourceLeadId` foi adicionado apenas na entidade, DTO Firestore e `CreateCustomerUseCase`; a camada Drift local (`CustomerLocalMapper`/`customers_table.dart`, usada pela carga offline somente-leitura da TASK-054) não foi alterada — ver Pendências.

## Regras Firebase implementadas
Não aplicável nesta task. `LeadDto` já modela o formato de documento Firestore (Timestamp, `organizationId` duplicado para Security Rules) para uso futuro, mas nenhuma Security Rule ou implementação de repositório Firestore foi criada.

## Analytics implementado
Não aplicável. Task de domínio/dados sem fluxo de UI ou evento comercial novo.

## Crashlytics implementado
Não aplicável. Falhas são retornadas como `AppResult`/`Failure` no domínio; não há captura nova de exceção em runtime.

## Impacto offline
Entidade inclui `LeadSyncStatus` e campos de auditoria/versionamento (`version`, `updatedAt/By`) preparando sincronização futura, no mesmo padrão de `Customer`. Nenhuma implementação de Drift, outbox ou carga offline foi criada para Lead nesta task.

## Impacto multi-tenant
`organizationId` é obrigatório e imutável em `Lead`, resolvido pelo chamador (sessão autenticada), nunca por input direto. Todos os use cases (`getById`, `create`, `update`) recebem `organizationId` explicitamente e o contrato `LeadRepository` é declarado para escopar por organização.

## Testes criados
- Igualdade por valor da entidade `Lead` (freezed).
- Máquina de estados completa em `Lead.canTransitionTo`: caminho padrão `newLead -> contacted -> qualified -> converted`, desqualificação a partir de `newLead` e de `contacted`, bloqueio de `disqualified -> converted`, bloqueio de qualquer transição de saída de `disqualified`/`converted`, bloqueio de atalhos `newLead -> qualified` e `newLead -> converted`, e bloqueio de `qualified -> disqualified`.
- `CreateLeadUseCase`: criação com trim de payload e validação de campos obrigatórios (`organizationId`, `responsibleUserId`).
- `MarkLeadContactedUseCase`: transição válida `newLead -> contacted` e bloqueio a partir de `converted`.
- `QualifyLeadUseCase`: transição válida a partir de `contacted`, bloqueio a partir de `newLead` e de `disqualified`.
- `DisqualifyLeadUseCase`: sucesso com motivo, falha sem motivo (sem tocar o repositório), bloqueio a partir de `converted`.
- `ConvertLeadToCustomerUseCase`: conversão de lead `qualified` gerando `Customer` com `sourceLeadId` preenchido e `Lead` atualizado (`converted`, `convertedCustomerId`, `convertedAt`); bloqueio quando o lead não está `qualified`.
- `ConvertLeadToOpportunityUseCase`: conversão de lead `qualified` vinculando `convertedOpportunityId`; bloqueio quando não está `qualified`; validação de `opportunityId` vazio.
- `LeadMapper`: `toEntity`/`toDto` round-trip, mapeamento de origem customizada (`LeadSource.custom`), e falhas de `status`/`syncStatus` desconhecidos.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format lib/features/leads lib/features/customers test/features/leads`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test/features/leads test/features/customers test/app/injection_test.dart`
- `flutter test` (suíte completa)

## Resultado do formatter
`dart format --set-exit-if-changed .`: `Formatted 801 files (0 changed)`, exit code 0.

## Resultado do analyzer
`flutter analyze`: `No issues found!` (11.7s).

## Resultado dos testes
`flutter test` (suíte completa): `All tests passed!` — 1195 testes, incluindo os 27 novos testes de Lead e os testes de `customers` (não quebrados pela adição de `sourceLeadId`) e `test/app/injection_test.dart` (grafo de DI ainda resolve).

## Riscos conhecidos
- `Customer.sourceLeadId` não foi propagado à camada Drift local (`CustomerLocalMapper`/`customers_table.dart`, usada pela carga offline somente-leitura da TASK-054); um `Customer` recarregado do cache local perde esse campo até uma task futura estender o schema Drift.
- `ConvertLeadToOpportunityUseCase` depende de um `opportunityId` já existente fornecido pelo chamador, porque `Opportunity` (TASK-057) ainda não existe; o fluxo real de criação da Opportunity a partir do Lead qualificado precisa ser fechado quando TASK-057/058 existirem.
- `MarkLeadContactedUseCase` foi uma extensão de escopo (ver Decisões técnicas) para tornar `LeadStatus.contacted` alcançável; se TASK-056 ou TASK-059/060 (atividades CRM) definirem um fluxo diferente para "marcar contato", este use case pode precisar de ajuste ou consolidação.
- Score (`Lead.score`) não tem algoritmo de cálculo; é apenas um campo numérico atribuído na criação (default 0), conforme a própria task permite adiar para TASK-062.

## Pendências
- Implementar `LeadRepository` (Firestore e/ou local) nas próximas tasks de cadastro/listagem (TASK-056).
- Modelar `Opportunity` (TASK-057) e então orquestrar a criação real da Opportunity dentro (ou a partir) de `ConvertLeadToOpportunityUseCase`, adicionando `sourceLeadId` a `Opportunity` espelhando `Customer.sourceLeadId`.
- Estender o schema Drift de `Customer` para persistir `sourceLeadId` localmente, se a rastreabilidade precisar sobreviver ao cache offline.
- Implementar o algoritmo de scoring de Lead (TASK-062).
- Catálogo configurável de motivos de desqualificação (TASK-061) — hoje `DisqualifyLeadUseCase.reason` é texto livre, conforme a própria task permite.

## Evidências
- `flutter analyze`: sem issues.
- `flutter test`: 1195/1195 testes passaram.
- Backlog atualizado para 55 / 220.

## Commit
`feat(leads): model lead domain and qualification pipeline`

## Push
Não realizado — sem autorização nesta rodada.

## Hash do commit
Informado na resposta final da task, após a criação do commit.

## Branch
main
