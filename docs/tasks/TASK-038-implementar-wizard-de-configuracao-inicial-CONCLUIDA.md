# TASK-038 — Concluída (2026-08-23)

## Resumo

Implementado o wizard multi-step de configuração inicial da Organization (`OnboardingWizardPage` +
`OnboardingBloc`, feature `lib/features/onboarding/`), consumindo o `CreateOrganizationUseCase`
(TASK-026/TASK-037) — que até esta task não tinha nenhuma tela/BLoC real chamando-o. O wizard tem 4
passos (dados da organização, segmento de moda, moeda/país, preferências iniciais), valida cada
passo antes de avançar, persiste o progresso localmente (`shared_preferences`, escopado por
`uid`) e retoma exatamente no passo salvo se o app for fechado antes de concluir. Ao concluir, cria
a Organization (com `id`/`slug` derivados automaticamente) e navega para a rota real da organização
criada (`AboutAppRoute(orgId: organization.id)`), substituindo o placeholder que `SignUpPage`
usava desde a TASK-035. Também foi adicionado um campo opcional `segment` a `OrganizationSettings`
(TASK-026) — inexistente até então — para que o segmento coletado no wizard seja de fato persistido
na Organization (Cloud Function `createOrganization`, TASK-037), sem quebrar nenhum chamador
existente (campo opcional, `null` por padrão).

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, BLoC, DI, extensão do modelo Organization,
  Cloud Function).
- `flutter-ui-design-specialist` (novo componente de Design System `AppWizardStepper`, telas dos 4
  passos, estados de loading/erro/validação).

## Arquivos criados

- `lib/features/onboarding/domain/value_objects/onboarding_step.dart` — enum dos 4 passos + helpers
  (`stepNumber`, `next`, `previous`, `isLast`).
- `lib/features/onboarding/domain/value_objects/organization_segment.dart` — enum do segmento de
  moda (`apparel`/`footwear`/`accessories`/`multiBrand`) + `code` normalizado.
- `lib/features/onboarding/domain/entities/onboarding_progress.dart` (+ `.freezed.dart`) — snapshot
  do progresso do wizard.
- `lib/features/onboarding/domain/validators/onboarding_step_validators.dart` — validação pura por
  campo/passo.
- `lib/features/onboarding/domain/repositories/onboarding_progress_repository.dart` — contrato de
  persistência local do progresso.
- `lib/features/onboarding/domain/usecases/get_onboarding_progress_use_case.dart`,
  `save_onboarding_progress_use_case.dart`, `clear_onboarding_progress_use_case.dart` — CRUD do
  progresso local.
- `lib/features/onboarding/domain/usecases/complete_onboarding_use_case.dart` — orquestra a
  conclusão: gera `id`/`slug`, revalida nome/segmento (defesa em profundidade) e delega ao
  `CreateOrganizationUseCase` já existente.
- `lib/features/onboarding/data/dtos/onboarding_progress_dto.dart`,
  `data/mappers/onboarding_progress_mapper.dart` — serialização JSON do progresso.
- `lib/features/onboarding/data/datasources/onboarding_progress_data_source.dart` (contrato) e
  `shared_preferences_onboarding_progress_data_source.dart` (implementação) — persistência local,
  tolerante a cache corrompido/desatualizado (nunca derruba o wizard).
- `lib/features/onboarding/data/repositories/onboarding_progress_repository_impl.dart`.
- `lib/features/onboarding/presentation/bloc/onboarding_event.dart`, `onboarding_state.dart` (+
  `.freezed.dart`), `onboarding_bloc.dart` — orquestra navegação entre passos, validação, persistência
  automática e submit.
- `lib/features/onboarding/presentation/pages/onboarding_wizard_page.dart` — página real, registrada
  na rota `OnboardingWizardRoute` (TASK-035 já apontava para ela).
- `lib/features/onboarding/presentation/widgets/onboarding_step_views.dart` — as 4 telas de passo.
- `lib/features/onboarding/onboarding.dart` — barrel da feature.
- `lib/core/design_system/components/navigation/app_wizard_stepper.dart` — novo componente de Design
  System (`AppWizardStepper`): barra de progresso segmentada + "Passo X de Y" + título do passo
  atual — o Design System ainda não tinha um stepper de wizard (só `AppQuantityStepper`, que é outra
  coisa).
- Testes correspondentes a cada arquivo acima em `test/features/onboarding/**` e
  `test/core/design_system/components/navigation/app_wizard_stepper_test.dart` (ver "Testes
  criados").
- `docs/tasks/TASK-038-implementar-wizard-de-configuracao-inicial-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `lib/features/organizations/domain/value_objects/organization_settings.dart` — novo campo opcional
  `segment` (nunca validado como obrigatório neste tipo — a obrigatoriedade é regra do wizard, não
  de `OrganizationSettings` em geral); `.validated()` ganhou o parâmetro opcional `segment`.
- `lib/features/organizations/domain/usecases/create_organization_use_case.dart` — novo parâmetro
  opcional `segment`, repassado a `OrganizationSettings.validated`.
- `lib/features/organizations/data/dtos/organization_settings_dto.dart` — `segment` opcional em
  `fromJson`/`toJson` (omitido quando `null`, nunca escrito como chave `null` explícita).
- `lib/features/organizations/data/mappers/organization_mapper.dart` — `settingsToEntity`/
  `settingsToDto` repassam `segment`.
- `lib/features/organizations/data/datasources/firestore_organization_data_source.dart` — inclui
  `segment` no payload da Cloud Function quando presente e faz o parsing de volta da resposta.
- `functions/src/organizations/create-organization.ts` — aceita `segment` opcional no payload,
  grava em `organizations/{id}.settings.segment` só quando informado (comportamento antigo
  preservado byte a byte quando `segment` não é enviado) e devolve no `settings` da resposta.
- `functions/test/create-organization.test.ts` — novo teste cobrindo persistência/omissão do
  `segment`.
- `lib/core/design_system/components/components.dart` — export do novo `AppWizardStepper`.
- `lib/core/navigation/app_route_paths.dart` — docstring de `OnboardingWizardRoute` atualizada (não
  é mais "declarada antes da implementação").
- `lib/core/navigation/app_router.dart` — novo `onboardingWizardPageBuilder` e `GoRoute` real para
  `OnboardingWizardRoute`.
- `lib/app/bootstrap.dart` — `VestiProApp` passa a injetar `OnboardingWizardPage` real no
  `AppRouter`.
- `lib/app/injection.config.dart` — regenerado (`dart run build_runner build`) com todo o novo grafo
  de DI da feature `onboarding` e do `AppWizardStepper` (nenhuma injeção nova para o componente em
  si, apenas para o BLoC/use cases/repositório/datasource).
- `test/core/navigation/app_router_test.dart`, `test/core/navigation/session_auth_guard_test.dart` —
  novo parâmetro obrigatório `onboardingWizardPageBuilder` no `AppRouter` de teste.
- `test/features/organizations/**` — cobertura nova para o campo `segment` (settings, use case,
  mapper, datasource).

Nenhum outro arquivo foi alterado. `lib/main.dart` tem uma modificação não relacionada a esta task
(troca de entrypoint `main_dev.dart`/`main_prod.dart`, deixada por uma sessão anterior) que foi
deliberadamente ignorada — não lida além do necessário para confirmar isso, não revertida, não
incluída em nenhum commit desta task.

## Arquitetura utilizada

- Clean Architecture feature-first: `lib/features/onboarding/{domain,data,presentation}`, seguindo
  exatamente a mesma separação/nomenclatura de `authentication`/`organizations`.
- `OnboardingWizardPage`/os 4 widgets de passo nunca acessam `SharedPreferences`,
  `OrganizationRepository` ou `OnboardingProgressRepository` diretamente — tudo passa por
  `OnboardingBloc`, que por sua vez só conhece use cases (`GetOnboardingProgressUseCase`,
  `SaveOnboardingProgressUseCase`, `ClearOnboardingProgressUseCase`, `CompleteOnboardingUseCase`) e
  `AuthRepository` (para o `uid` da sessão atual, mesmo padrão já usado por `SessionAuthGuard`).
- `CompleteOnboardingUseCase` não duplica nenhuma regra do `CreateOrganizationUseCase` já existente
  (TASK-026/TASK-037): ele só deriva `id`/`slug` (responsabilidade nova, do wizard) e delega toda a
  criação/validação de negócio ao use case já testado.
- `SharedPreferencesOnboardingProgressDataSource` resolve `SharedPreferences.getInstance()` a cada
  chamada (o plugin já cacheia a instância internamente) em vez de registrá-la em
  `AppInjectionModule`, evitando introduzir a primeira dependência `@preResolve` assíncrona do
  bootstrap só para esta feature.
- `CompleteOnboardingUseCase` tem construtor padrão (usado pelo `injectable`) e um construtor nomeado
  `.withDependencies(...)` para testes substituírem o `Uuid` — mesmo padrão já usado por
  `CloudFunctionsService.withDependencies`, necessário porque a classe é `final` e não pode ser
  mockada via `implements` fora de sua própria library.

## Regras de negócio implementadas

- Não é possível avançar de um passo sem que os campos daquele passo passem na validação
  (`OnboardingBloc._validateStep`/`_applyStepError`).
- Não é possível concluir o wizard sem nome da organização e segmento selecionado — revalidado tanto
  no `OnboardingBloc` (UX) quanto no `CompleteOnboardingUseCase` (defesa em profundidade).
- Moeda, país e idioma padrão vêm pré-preenchidos com um valor padrão sensato (`BRL`/`BR`/`pt-BR`) —
  o usuário pode trocá-los, mas nunca é bloqueado neles, conforme a regra do próprio backlog ("não
  permitir concluir sem os campos obrigatórios mínimos: nome e segmento").
- `slug` é derivado do nome da organização (normalizado, sem acentos, minúsculo, hifenizado) + um
  sufixo curto do `id` gerado, já que `slug` ainda não tem verificação de unicidade server-side.
- Progresso salvo é sempre escopado por `uid` — nunca um "slot" global no dispositivo.
- Ao concluir com sucesso, o progresso local salvo é apagado (nunca resurge num onboarding já
  finalizado).

## Regras Firebase implementadas

- `createOrganization` (Cloud Function) passa a aceitar `segment` opcional e grava
  `organizations/{id}.settings.segment` apenas quando informado — comportamento 100% compatível com
  chamadas antigas (sem `segment`, o documento fica idêntico ao que já era gravado antes desta
  task).
- Nenhuma alteração em `firestore.rules`: a escrita de `organizations` já era exclusiva da Cloud
  Function (Admin SDK, TASK-037) e a regra de `update` não restringe os campos internos de
  `settings`, então o novo campo não exigiu nenhuma mudança de Security Rules.

## Analytics implementado

- `AnalyticsEvents.organizationCreated` (já existente desde TASK-017, nunca disparado antes desta
  task) agora é logado por `OnboardingBloc` ao concluir o wizard com sucesso — com um único
  parâmetro, `segment` (categoria de moda, nunca dado pessoal), nunca o nome da organização.
- Abandono de passo (mencionado como opcional pela própria task — "sem bloquear a saída do
  usuário") não foi implementado: exigiria interceptar a navegação de saída da página sem nenhum
  requisito de UX definido para isso, e o próprio backlog marca esse evento como opcional. Registrado
  como pendência abaixo.

## Crashlytics implementado

Nenhuma captura nova específica: toda falha de use case já propaga `Failure`/`AppException` pelos
caminhos centrais existentes (`CrashReporter`, TASK-016) — nenhum `print`, nenhuma exceção engolida
silenciosamente (a única exceção deliberadamente "engolida" é a leitura de um cache local
corrompido/no formato antigo, tratada como "sem progresso salvo", documentada no próprio código).

## Impacto offline

- O progresso do wizard (rascunho local) é 100% offline-first: `shared_preferences` funciona sem
  rede e sobrevive ao fechamento do app.
- A conclusão do wizard (criação real da Organization) permanece uma operação online-only, mesma
  característica já aceita pela TASK-037 para a criação da primeira Organization (não é uma mutação
  de negócio comum que se beneficie de fila offline/Outbox).

## Impacto multi-tenant

- Nenhuma organização existe antes da conclusão do wizard, então não há isolamento de tenant a
  preservar durante os passos em si — o único dado sensível ao tenant é o resultado final
  (`Organization` criada), que continua exclusivamente criado pela Cloud Function `createOrganization`
  (Admin SDK), nunca pelo client.
- O progresso local do wizard é escopado por `uid` (nunca por `organizationId`, que ainda não existe
  nesse momento do fluxo).

## Testes criados

- `test/features/onboarding/domain/validators/onboarding_step_validators_test.dart` — validação pura
  por campo.
- `test/features/onboarding/domain/usecases/onboarding_progress_use_cases_test.dart` — get/save/clear
  delegando ao repositório.
- `test/features/onboarding/domain/usecases/complete_onboarding_use_case_test.dart` — derivação de
  `id`/`slug` (incluindo remoção de acentos/caracteres especiais), bloqueio sem nome/segmento,
  propagação de falha de rede.
- `test/features/onboarding/data/dtos/onboarding_progress_dto_test.dart` — round-trip JSON, payload
  malformado.
- `test/features/onboarding/data/mappers/onboarding_progress_mapper_test.dart` — round-trip
  entidade/DTO, índice de passo fora do intervalo.
- `test/features/onboarding/data/datasources/shared_preferences_onboarding_progress_data_source_test.dart`
  — persistência por usuário, cache corrompido/formato inesperado tratado como "sem progresso".
- `test/features/onboarding/data/repositories/onboarding_progress_repository_impl_test.dart`.
- `test/features/onboarding/presentation/bloc/onboarding_bloc_test.dart` — retomada de progresso
  salvo, edição de campo persistindo automaticamente, navegação entre passos bloqueada/permitida por
  validação, conclusão bloqueada sem nome/segmento, conclusão com sucesso (limpa progresso, loga
  analytics), falha de repositório, usuário não autenticado.
- `test/features/onboarding/presentation/pages/onboarding_wizard_page_test.dart` — teste de widget
  simulando fechamento/reabertura do wizard (retoma no passo salvo com o nome já preservado ao
  voltar), bloqueio de avanço sem nome, fluxo completo dos 4 passos até a navegação final.
- `test/core/design_system/components/navigation/app_wizard_stepper_test.dart` — legendas/"Passo X
  de Y" e semântica de acessibilidade do novo componente.
- `test/features/organizations/domain/value_objects/organization_settings_test.dart`,
  `domain/usecases/create_organization_use_case_test.dart`,
  `data/mappers/organization_mapper_test.dart`,
  `data/datasources/firestore_organization_data_source_test.dart` — cobertura do novo campo
  `segment` (trim/normalização para `null`, encaminhamento pelo use case, round-trip no mapper,
  payload/parsing da Cloud Function).
- `functions/test/create-organization.test.ts` — novo teste cobrindo persistência/omissão do
  `segment` na Cloud Function.

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test
cd functions && npm run build
cd functions && npm run lint
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only firestore "npm --prefix functions test -- create-organization"
firebase emulators:exec --only firestore "npm --prefix functions test"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
```

## Resultado do formatter

`dart format --set-exit-if-changed .` → `Formatted 494 files (0 changed) in 1.92 seconds.` (última
passada, após todos os ajustes).

## Resultado do analyzer

`flutter analyze` → `No issues found! (ran in 10.7s)`.

## Resultado dos testes

- `flutter test` (suíte completa): `+850: All tests passed!` (eram `+795` antes desta task — 55
  testes novos, incluindo os da extensão de `segment` em `organizations`).
- `npm run build` (functions/TypeScript): sem erros.
- `npm run lint` (functions/ESLint): sem erros/avisos.
- `firebase emulators:exec --only firestore "npm --prefix functions test -- create-organization"`:
  `Tests: 8 passed, 8 total` (era 7 antes; +1 teste novo de `segment`).
- `firebase emulators:exec --only firestore "npm --prefix functions test"`: `Test Suites: 3 passed,
  3 total` / `Tests: 15 passed, 15 total` (era 14 antes).
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"`: `Tests: 51 passed,
  51 total` (inalterado — nenhuma mudança de Security Rules foi necessária).

## Decisões técnicas

- **Adicionar `segment` a `OrganizationSettings` (não modelado pela TASK-026)**: o backlog original
  da TASK-038 exige coletar e validar o segmento como campo obrigatório para concluir o wizard, e o
  critério de aceite "Dados persistidos corretamente na Organization ao concluir o wizard" só é
  cumprido de fato se o segmento é realmente gravado — não apenas coletado na UI. Implementado como
  campo **opcional** (nunca `required`) em todas as camadas (`OrganizationSettings`,
  `OrganizationSettingsDto`, `CreateOrganizationUseCase`, Cloud Function) para não quebrar nenhum
  chamador/teste já existente: toda chamada antiga (sem `segment`) continua produzindo exatamente o
  mesmo resultado de antes, comprovado pelos testes que passam sem alteração.
- **`AppWizardStepper` como novo componente de Design System, não reaproveitamento de
  `AppQuantityStepper`**: são conceitos completamente diferentes (indicador de progresso de wizard vs.
  controle de incremento/decremento de quantidade) apesar do nome parecido — reaproveitar teria sido
  forçar uma API errada. Nome escolhido deliberadamente distinto (`AppWizardStepper`, não
  `AppStepper`) para não colidir semanticamente com `AppQuantityStepper`.
- **`shared_preferences` em vez de uma tabela Drift dedicada**: a task permite explicitamente
  qualquer uma das duas opções ("ex.: `shared_preferences` ou tabela local dedicada"); como nenhuma
  configuração de Drift existe ainda no projeto (dependência presente no `pubspec.yaml`, mas nenhum
  banco/tabela configurado em código), introduzir a primeira tabela Drift do projeto só para um
  rascunho textual pequeno seria desproporcional ao risco/escopo desta task.
- **Nenhum "cache de organização ativa" (`ActiveOrganizationSession`) construído nesta task**: a
  TASK-037 registrou como pendência "atualizar o estado local de organização ativa para navegação"
  como responsabilidade da TASK-038. Interpretei isso da forma mais estritamente necessária e
  justificada: `OnboardingBloc` devolve a `Organization` recém-criada (com `id` real) e
  `OnboardingWizardPage` navega com esse `id` real (`AboutAppRoute(orgId: organization.id)`),
  substituindo o placeholder usado desde a TASK-035 — sem inventar uma nova camada de sessão/cache
  de "organização ativa" fora do escopo explícito desta task (critérios de aceite da TASK-038 não
  mencionam esse item). Essa camada mais ampla (sessão persistente, incluindo organização ativa em
  cache) é explicitamente o escopo da TASK-041 ("sessão persistente e logout"), que já prevê limpar
  "organização ativa em cache" no logout — construí-la agora, sem o guard/sessão real que a
  consumiria, repetiria o mesmo risco de "dependência quebrada" que a TASK-026/TASK-037 já registraram
  e evitaram deliberadamente.
- **`CompleteOnboardingUseCase` com construtor padrão + `.withDependencies` nomeado**: mesmo padrão
  já usado por `CloudFunctionsService` — o construtor que `injectable` gera provider para não recebe
  `Uuid` nenhum (evitando que o gerador tente resolvê-lo via DI), e testes usam o construtor nomeado
  para injetar um `Uuid` mockado deterministicamente.
- **`OnboardingOrganizationDetailsStep` como único passo `StatefulWidget`**: precisa de um
  `TextEditingController` próprio, seedado uma única vez (em `initState`) a partir do
  `OnboardingBloc.state.organizationName` já resolvido — os outros 3 passos usam `AppDropdown`/botões
  de seleção, cuja exibição já é 100% derivada do estado a cada rebuild, sem necessidade de um
  controller próprio.

## Riscos conhecidos

- Evento de analytics de "abandono de passo" não implementado (item explicitamente opcional no texto
  da task).
- `slug` ainda não tem verificação de unicidade server-side (`CreateOrganizationUseCase`/Cloud
  Function já documentavam esse risco antes desta task) — a derivação automática de `slug` desta
  task não piora nem resolve esse risco pré-existente.
- `OrganizationSettingsDto.segment`/`OrganizationSettings.segment` documentam explicitamente que
  `FirestoreOrganizationDataSource.updateSettings` substitui o mapa `settings` inteiro (via
  `update()`, não um merge profundo) — uma futura tela de "editar segmento nas Configurações" (fora
  do escopo desta task) precisa sempre reenviar `segment` junto de `currency`/`country`/
  `defaultLanguage`, ou o valor gravado será perdido. Comportamento pré-existente (já valia para os 3
  campos originais), apenas mais visível agora que há um 4º campo.
- `AlwaysAllowActiveOrganizationGuard` continua sendo o guard de rota real (nenhuma rota `:orgId`
  além de `AboutAppRoute` — que já existia — precisa dele hoje); substituí-lo por um guard real
  segue sendo escopo de uma task futura (TASK-041/TASK-042), como já registrado pela TASK-037.

## Pendências

- Evento de analytics de abandono de passo (opcional, não implementado — ver "Riscos conhecidos").
- Sessão/cache real de "organização ativa" e substituição de `AlwaysAllowActiveOrganizationGuard" —
  escopo da TASK-041 (sessão persistente, logout e revogação).
- Edição do segmento/moeda/país/idioma após a conclusão do wizard fica, como o próprio texto da task
  já previa, para a tela de Configurações da organização (fora do escopo desta task).

## Evidências

- `lib/features/onboarding/**` (feature completa) e seus testes em `test/features/onboarding/**`.
- `lib/core/design_system/components/navigation/app_wizard_stepper.dart` e seu teste.
- `functions/src/organizations/create-organization.ts`/`functions/test/create-organization.test.ts`
  (novo teste de `segment`).
- Saídas de `flutter test` (`+850: All tests passed!`), `firebase emulators:exec --only firestore
  "npm --prefix functions test"` (`Tests: 15 passed, 15 total`) e `firebase emulators:exec --only
  firestore "npm --prefix firestore-tests test"` (`Tests: 51 passed, 51 total`), reproduzidas nas
  seções "Resultado dos testes" acima.

## Commit

Criado com sucesso (`lib/main.dart`, alteração pré-existente não relacionada a esta task, foi
deliberadamente deixado de fora do commit).

## Push

Autorizado nesta rodada; executado após o commit.

## Hash do commit

Ver seção "Commit" da resposta final.

## Branch

`main`
