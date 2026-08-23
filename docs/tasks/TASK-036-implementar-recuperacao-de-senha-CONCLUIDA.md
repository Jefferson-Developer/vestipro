# TASK-036 — Concluída (2026-08-23)

## Resumo

Implementado o fluxo completo de recuperação de senha via Firebase Auth: tela
`ForgotPasswordPage`, `ForgotPasswordBloc` e o caso de uso
`SendPasswordResetEmailUseCase`, reaproveitando o `AuthRepository` já existente
(TASK-012) e o link "Esqueci minha senha" já presente em `LoginForm`
(TASK-034). A mensagem de sucesso é sempre idêntica para conta existente e
inexistente (`user-not-found`), prevenindo enumeração de contas. A rota
`PasswordResetRoute`, já declarada desde TASK-034, foi registrada no
`AppRouter`.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/features/authentication/domain/usecases/send_password_reset_email_use_case.dart`
- `lib/features/authentication/presentation/bloc/forgot_password_event.dart`
- `lib/features/authentication/presentation/bloc/forgot_password_event.freezed.dart` (gerado)
- `lib/features/authentication/presentation/bloc/forgot_password_state.dart`
- `lib/features/authentication/presentation/bloc/forgot_password_state.freezed.dart` (gerado)
- `lib/features/authentication/presentation/bloc/forgot_password_bloc.dart`
- `lib/features/authentication/presentation/widgets/forgot_password_form.dart`
- `lib/features/authentication/presentation/pages/forgot_password_page.dart`
- `test/features/authentication/domain/usecases/send_password_reset_email_use_case_test.dart`
- `test/features/authentication/presentation/bloc/forgot_password_bloc_test.dart`
- `test/features/authentication/presentation/pages/forgot_password_page_test.dart`

## Arquivos alterados

- `lib/features/authentication/authentication.dart` — exporta `ForgotPasswordPage`.
- `lib/core/analytics/analytics_events.dart` — adiciona `passwordResetRequested`.
- `lib/core/navigation/app_route_paths.dart` — atualiza a doc de `PasswordResetRoute`
  (agora implementada) e a referência cruzada em `OnboardingWizardRoute`.
- `lib/core/navigation/app_router.dart` — novo parâmetro obrigatório
  `forgotPasswordPageBuilder` e `GoRoute` para `PasswordResetRoute`.
- `lib/app/bootstrap.dart` — conecta `ForgotPasswordPage`/`ForgotPasswordBloc`
  via `getIt` no `AppRouter` real.
- `lib/app/injection.config.dart` — regenerado pelo `build_runner`
  (registro de `SendPasswordResetEmailUseCase` e `ForgotPasswordBloc`).
- `test/core/navigation/app_router_test.dart` — helper de teste passa a
  fornecer `forgotPasswordPageBuilder`.
- `test/core/navigation/session_auth_guard_test.dart` — idem.
- `test/core/analytics/analytics_events_test.dart` — inclui
  `password_reset_requested` na taxonomia esperada.

## Arquitetura utilizada

Feature-first + Clean Architecture, seguindo exatamente o precedente de
`LoginBloc`/`LoginPage` (TASK-034):

`ForgotPasswordPage` → `ForgotPasswordBloc` → `SendPasswordResetEmailUseCase`
→ `AuthRepository` (contrato já existente em `core/auth/`) →
`AuthRepositoryImpl`/`FirebaseAuthDataSource`.

`ForgotPasswordForm`/`ForgotPasswordPage` nunca chamam `AuthRepository`/
`firebase_auth` diretamente; toda transição de estado passa pelo bloc. O
validador de e-mail (`validateLoginEmail`) foi reaproveitado de
`login_form_validators.dart` em vez de duplicado, pois a regra ("parece um
e-mail") é idêntica à do login.

## Regras de negócio implementadas

- **Prevenção de enumeração de contas**: `SendPasswordResetEmailUseCase`
  mapeia a falha `user-not-found` do Firebase para o mesmo `AppSuccess<void>`
  retornado para uma conta existente — esse mapeamento ocorre inteiramente no
  domain, nunca no bloc ou na tela. `ForgotPasswordPage` sempre exibe a mesma
  string (`kPasswordResetGenericMessage`) para esse status.
- E-mail mal formatado é bloqueado no cliente antes de chamar o use case
  (`validateLoginEmail`); se o Firebase ainda assim retornar `invalid-email`,
  o use case reescreve a mensagem para "Informe um e-mail válido." (a
  mensagem padrão do mapper genérico, "E-mail ou senha inválidos.", foi
  escrita para o fluxo de login e mencionaria "senha" indevidamente aqui).
- `too-many-requests` é reescrito para "Muitas tentativas. Tente novamente
  mais tarde." (mesmo raciocínio: a mensagem padrão do mapper menciona
  "login").
- Falha de rede (`ConnectivityFailure`) e demais falhas passam intactas.
- Nenhuma mensagem técnica/código do Firebase chega à UI.

## Regras Firebase implementadas

Nenhuma regra nova de Firestore/Storage — o fluxo usa exclusivamente
`FirebaseAuth.sendPasswordResetEmail`, já exposto por
`AuthRepository`/`FirebaseAuthDataSource` desde TASK-012 (conectado ao Auth
Emulator fora de produção).

## Analytics implementado

Novo evento `password_reset_requested` em `AnalyticsEvents`, disparado pelo
`ForgotPasswordBloc` em toda submissão bem-sucedida (incluindo o caso
`user-not-found`, que já chega ao bloc como sucesso). Os parâmetros enviados
são apenas `platform` (metadado técnico) — nunca o e-mail informado, conforme
a restrição de LGPD documentada em `AGENTS.md`.

## Crashlytics implementado

Nenhuma alteração — este fluxo não introduz novos pontos de captura de erro
fora do já existente `configureGlobalErrorHandlers`/`CrashReporter`.

## Impacto offline

Nenhum. O envio de e-mail de redefinição de senha exige conectividade com o
Firebase Auth; uma falha de rede já é tratada e exibida como
`ConnectivityFailure` amigável, sem persistência local/Outbox (não é uma
mutação de domínio comercial).

## Impacto multi-tenant

Nenhum. `sendPasswordResetEmail` opera inteiramente sobre a conta do Firebase
Auth, antes de qualquer resolução de `organizationId`/tenant.

## Testes criados

- `send_password_reset_email_use_case_test.dart`: sucesso, `user-not-found`
  → sucesso genérico, `invalid-email` → mensagem reescrita, `too-many-requests`
  → mensagem reescrita, falha de conectividade propagada intacta, trim do
  e-mail antes de delegar ao repositório.
- `forgot_password_bloc_test.dart`: limpeza de erro/falha ao editar o e-mail,
  rejeição de e-mail vazio/mal formatado sem chamar o use case, submissão com
  sucesso e evento de analytics sem dado pessoal, `user-not-found` chegando ao
  mesmo estado de sucesso, falha de conectividade e de `too-many-requests`
  preservando o e-mail digitado, `droppable` (segunda submissão ignorada
  durante envio em andamento).
- `forgot_password_page_test.dart`: rejeição local de submissão vazia sem
  chamar o repositório, estado de carregamento bloqueando um segundo tap,
  mensagem de sucesso **idêntica** para conta existente e para
  `user-not-found`, mensagem amigável de falha de conectividade sem limpar o
  e-mail digitado, navegação de volta para `LoginRoute` via "Voltar para o
  login".

## Comandos executados

```bash
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`Formatted 460 files (0 changed) in 1.90 seconds.` — sem alterações
pendentes.

## Resultado do analyzer

`Analyzing VestiPro... No issues found! (ran in 11.0s)`

## Resultado dos testes

`flutter test` completo: **792 testes, todos passando** (nenhuma falha).

## Decisões técnicas

- Reaproveitado `validateLoginEmail` (login_form_validators.dart) em vez de
  criar um novo validador de e-mail para o formulário de recuperação — regra
  idêntica, evitando duplicação (AGENTS.md).
- O mapeamento `user-not-found → sucesso genérico` foi colocado no use case
  (`SendPasswordResetEmailUseCase`), e não no bloc/tela, exatamente como a
  task exige ("nunca na tela diretamente"). O bloc também nunca vê esse
  código de erro — ele já chega como `AppSuccess<void>`.
- Reescrita pontual das mensagens de `invalid-email`/`too-many-requests` no
  próprio use case (em vez de alterar `firebase_auth_exception_mapper.dart`,
  que é compartilhado por login/cadastro) — evita quebrar/alterar o
  comportamento de mensagens já testado para o fluxo de login, mantendo o
  ajuste de copy isolado ao fluxo de recuperação de senha.
- Layout da página propositalmente mais simples que `LoginPage`/`SignUpPage`
  (sem split desktop/brand panel) — é uma tela secundária e de baixa
  frequência de uso; segue os mesmos tokens do Design System.

## Riscos conhecidos

- Se, futuramente, o mapper genérico do Firebase (`firebase_auth_exception_mapper.dart`)
  mudar o texto/código de `invalid-email`/`too-many-requests`, o remapeamento
  local em `SendPasswordResetEmailUseCase` deve ser revisado para continuar
  coerente.
- Não há teste de e2e/integration contra o Auth Emulator especificamente para
  `sendPasswordResetEmail` (já cobertos os demais métodos de
  `FirebaseAuthDataSource` em `firebase_auth_data_source_integration_test.dart`
  desde TASK-012) — não fazia parte do escopo obrigatório desta task.

## Pendências

Nenhuma pendência relevante para o escopo desta task.

## Evidências

- `flutter analyze`: nenhum problema encontrado.
- `flutter test`: 792 testes, todos passando (inclui os 19 novos testes desta
  task e o ajuste do teste de taxonomia de analytics).

## Commit

Único commit contendo implementação, testes, documentação e atualização do
backlog (`docs/tasks/TASKS.md`).

## Push

Autorizado nesta execução; realizado após o commit local (ver relatório
final da task).

## Hash do commit

Ver relatório final da task (mensagem de resposta) para o hash real.

## Branch

`main`
