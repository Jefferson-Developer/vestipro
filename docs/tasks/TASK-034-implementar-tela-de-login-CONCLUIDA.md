# TASK-034 — Concluída (2026-08-23)

## Resumo

Implementada a tela de login por e-mail/senha do VestiPro (EPIC-04), com arquitetura
Clean/feature-first + BLoC sobre o `AuthRepository`/Firebase Authentication já configurados na
TASK-012, e UI construída 100% sobre o Design System (EPIC-02). Cobre estados de
inicial/validando/carregando/sucesso/falha, mensagens de erro amigáveis e não-enumeráveis,
toggle de visibilidade de senha, navegação tipada para "Esqueci minha senha" e evento de
analytics `login_completed` sem dados pessoais.

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domain/data, BLoC, DI, navegação, analytics, testes).
- `flutter-ui-design-specialist` (uso e pequena extensão do Design System: layout responsivo da
  tela de login e suporte a `obscureText` em `AppTextField`).

## Arquivos criados

- `lib/features/authentication/domain/usecases/sign_in_with_email_and_password_use_case.dart`
- `lib/features/authentication/domain/validators/login_form_validators.dart`
- `lib/features/authentication/presentation/bloc/login_event.dart` (+ `.freezed.dart` gerado)
- `lib/features/authentication/presentation/bloc/login_state.dart` (+ `.freezed.dart` gerado)
- `lib/features/authentication/presentation/bloc/login_bloc.dart`
- `lib/features/authentication/presentation/pages/login_page.dart`
- `lib/features/authentication/presentation/widgets/login_form.dart`
- `lib/features/authentication/authentication.dart` (barrel da feature)
- `test/features/authentication/domain/domain_import_boundary_test.dart`
- `test/features/authentication/domain/validators/login_form_validators_test.dart`
- `test/features/authentication/domain/usecases/sign_in_with_email_and_password_use_case_test.dart`
- `test/features/authentication/presentation/bloc/login_bloc_test.dart`
- `test/features/authentication/presentation/pages/login_page_test.dart`

## Arquivos alterados

- `lib/core/design_system/components/inputs/app_text_field.dart` — adicionado o parâmetro
  `obscureText` (default `false`, retrocompatível), necessário para o campo de senha; nenhum
  componente existente muda de comportamento.
- `lib/core/navigation/app_route_paths.dart` — `LoginRoute` deixou de ser "não registrada ainda"
  (comentário atualizado) e foi adicionada `PasswordResetRoute` (rota tipada, ainda sem `GoRoute`
  próprio — pré-declarada para a TASK-036, mesmo precedente que `LoginRoute` tinha antes desta
  task).
- `lib/core/navigation/app_router.dart` — novo parâmetro obrigatório `loginPageBuilder` e registro
  do `GoRoute` de `LoginRoute`. `AlwaysAllowAuthGuard` continua sendo o guard default (não
  troquei para `SessionAuthGuard`: essa troca é responsabilidade da TASK-041, para não duplicar a
  lógica de persistência de sessão).
- `lib/app/bootstrap.dart` — `VestiProApp` agora injeta o `loginPageBuilder` real via
  `getIt<LoginBloc>()`.
- `lib/app/injection.config.dart` — regenerado pelo `build_runner` (registro de
  `SignInWithEmailAndPasswordUseCase` e `LoginBloc`).
- `pubspec.yaml` — declarado `assets/images/logo.png` (único asset de marca já existente no
  repositório e agora efetivamente usado, pela tela de login).
- `test/core/design_system/components/inputs/app_text_field_test.dart` — dois testes cobrindo o
  novo `obscureText`.
- `test/core/navigation/app_router_test.dart` — helper `_buildRouter` passa a exigir/aceitar
  `loginPageBuilder`; novo teste garantindo que a rota `/login` renderiza a página injetada.
- `test/core/navigation/session_auth_guard_test.dart` — os dois testes que antes esperavam cair na
  página "Página não encontrada" (por `LoginRoute` não ter `GoRoute` ainda) agora esperam a página
  de login real.

## Arquitetura utilizada

Presentation (`LoginPage`/`LoginView`/`LoginForm`) → `LoginBloc` → `SignInWithEmailAndPasswordUseCase`
→ `AuthRepository` (contrato já existente em `lib/core/auth/`, implementado sobre `firebase_auth`
desde a TASK-012). A UI nunca importa `firebase_auth`/`AuthRepository` diretamente — só o bloc.
Eventos (`LoginEvent`, freezed sealed): `emailChanged`, `passwordChanged`,
`passwordVisibilityToggled`, `submitted`. Estado único (`LoginState`, freezed, não-sealed) com
`email`/`password`/`emailError`/`passwordError`/`obscurePassword`/`status`/`failure` — optei por um
único estado (em vez de subclasses seladas por status) justamente para que um erro/falha nunca
tenha um motivo estrutural para "esquecer" ou limpar o que o usuário digitou.

## Regras de negócio implementadas

- Validação client-side pura (`validateLoginEmail`/`validateLoginPassword`, sem import de Flutter)
  roda antes de qualquer chamada ao `AuthRepository`; e-mail vazio/mal formatado e senha vazia
  nunca chegam ao Firebase.
- Mensagens de erro de autenticação (`user-not-found`, `wrong-password`, `invalid-credential`)
  já eram mapeadas para a mensagem genérica "E-mail ou senha inválidos." em
  `firebase_auth_exception_mapper.dart` (TASK-012) — não alterei esse mapeamento, apenas confirmei
  via teste que o bloc propaga a `Failure` tal como recebida, sem nunca reintroduzir o código/e-mail
  cru na UI.
- Duplo envio bloqueado em duas camadas: `AppButton` (tap-lock/`isLoading`) e o bloc
  (`transformer: droppable()` no evento `submitted`).
- Campos nunca são limpos após erro: os `TextEditingController`s do `LoginForm` só mudam por
  digitação do usuário, nunca são resincronizados a partir do estado do bloc.
- Link "Esqueci minha senha" navega via `context.go(const PasswordResetRoute().location)` (rota
  tipada); a página de destino real é responsabilidade da TASK-036 (hoje cai no `NotFoundPage` se
  acessada fora deste fluxo de teste, mesmo padrão que `LoginRoute` tinha antes desta task).
- Sucesso navega para a área autenticada placeholder já usada pelo restante do app
  (`AboutAppRoute(orgId: kPlaceholderOrganizationId)`), sem inventar uma nova convenção.

## Regras Firebase implementadas

Nenhuma nova regra de Firestore/Storage — a tela consome apenas Firebase Authentication, já
configurado (TASK-012) e já validado. Nenhuma alteração em Security Rules.

## Analytics implementado

`AnalyticsEvents.loginCompleted` disparado após sucesso, com `parameters: {'method': 'email',
'platform': defaultTargetPlatform.name}` — sem e-mail, uid ou qualquer dado pessoal (coberto por
teste que verifica ausência da chave `email` e do valor do e-mail digitado nos parâmetros).

## Crashlytics implementado

Nenhuma instrumentação nova necessária: falhas de login são erros de negócio esperados (tratados
como `Failure`), não erros inesperados — seguem fora do caminho de `CrashReporter`, mesmo critério
já usado no restante do app.

## Impacto offline

Nenhum. Login sempre depende de rede (Firebase Auth); falha de rede já é mapeada para
`ConnectivityFailure` e exibida como mensagem amigável, sem tentativa de fila offline (não faz
sentido para autenticação). Comportamento offline do restante do app não foi tocado.

## Impacto multi-tenant

Nenhuma leitura/gravação de dado de tenant nesta tela — login apenas autentica o usuário no
Firebase; resolução de organização ativa continua responsabilidade de tasks futuras
(TASK-026/TASK-037/TASK-041). `SessionAuthGuard`, que decide o redirecionamento por sessão, não foi
trocado como guard default do `AppRouter` (permanece `AlwaysAllowAuthGuard`) para não antecipar a
TASK-041.

## Testes criados

- `test/features/authentication/domain/domain_import_boundary_test.dart`: domínio da feature não
  importa Flutter/Firebase/Firestore/Drift.
- `test/features/authentication/domain/validators/login_form_validators_test.dart`: e-mail
  nulo/vazio/espaços/mal formatado/válido; senha nula/vazia/válida.
- `test/features/authentication/domain/usecases/sign_in_with_email_and_password_use_case_test.dart`:
  delega ao `AuthRepository` e propaga sucesso/falha sem alterar.
- `test/features/authentication/presentation/bloc/login_bloc_test.dart` (`bloc_test`): edição de
  campo limpa erro/falha antiga; toggle de senha; submit vazio (sem chamar o repositório); e-mail
  mal formatado (sem chamar o repositório); sucesso com trim do e-mail e evento de analytics sem
  dados pessoais; credencial inválida (mensagem genérica, campos preservados); falha de rede
  (`ConnectivityFailure`); `too-many-requests` (`ServerFailure`); segundo submit em voo é descartado
  (`droppable`) e loga analytics uma única vez.
- `test/features/authentication/presentation/pages/login_page_test.dart` (widget): labels
  persistentes mesmo após digitar; validação local sem chamar o repositório; loading no botão +
  bloqueio de duplo tap; mensagem de erro sem apagar os campos digitados; toggle de visibilidade de
  senha; navegação para `/password-reset` via "Esqueci minha senha"; navegação por teclado (Tab) de
  e-mail para senha (Web).
- `test/core/design_system/components/inputs/app_text_field_test.dart`: dois novos casos para
  `obscureText`.
- `test/core/navigation/app_router_test.dart`: nova rota `/login` renderiza o builder injetado.
- `test/core/navigation/session_auth_guard_test.dart`: dois testes atualizados para refletir que
  `/login` agora tem página real.

## Comandos executados

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/features/authentication test/core/design_system/components/inputs/app_text_field_test.dart test/core/navigation/app_router_test.dart test/core/navigation/session_auth_guard_test.dart
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` reformatou 7 arquivos (apenas estilo, sem mudança de lógica)
na primeira execução; execução subsequente ficaria limpa (não foi reexecutada após a reformatação
porque nenhum arquivo foi tocado depois dela).

## Resultado do analyzer

`flutter analyze` → `No issues found!` (após corrigir o `session_auth_guard_test.dart`, que
inicialmente falhava com `missing_required_argument` por não passar o novo `loginPageBuilder`).

## Resultado dos testes

`flutter test` → `00:25 +710: All tests passed!` (710 testes, 0 falhas). O log imprime um stack
trace de "Error while creating FirebaseRemoteConfig" durante `test/widget_test.dart` — isso é
comportamento pré-existente e esperado: `_resolveShowInsightsShortcut` (TASK-018) já captura essa
exceção em `try/catch` e apenas registra via `developer.log` quando o Remote Config real não está
disponível no ambiente de teste; não é uma falha de teste e não foi introduzido por esta task.

## Decisões técnicas

- Estendi `AppTextField` com `obscureText` em vez de criar um campo de senha paralelo fora do
  Design System — mantém um único componente de texto reutilizável, com todos os campos futuros de
  senha (cadastro, troca de senha) se beneficiando da mesma mudança.
- `LoginState` é uma única classe freezed (não uma união selada por status) para eliminar
  estruturalmente qualquer risco de um estado de erro "esquecer" `email`/`password`.
- Naveguei para a área autenticada usando o mesmo placeholder (`AboutAppRoute` +
  `kPlaceholderOrganizationId`) que `AppRouter.initialLocation`/`ForbiddenPage`/`NotFoundPage` já
  usam, em vez de inventar uma nova convenção antes de organização real existir (TASK-026/037).
- `PasswordResetRoute` foi pré-declarada (sem `GoRoute` próprio ainda) seguindo exatamente o
  precedente documentado que `LoginRoute` já tinha antes desta task, para a TASK-036 só precisar
  registrar o `GoRoute`/builder real.
- Não troquei o guard default do `AppRouter` para `SessionAuthGuard` — isso é a responsabilidade
  explícita da TASK-041 (persistência de sessão), e trocar agora anteciparia esse trabalho e
  quebraria o teste `bootstrap_test.dart` que hoje assume acesso direto à página placeholder.
- Evento de analytics carrega apenas `method`/`platform` (via `defaultTargetPlatform.name`),
  nunca e-mail/uid, coberto por teste.

## Riscos conhecidos

- `PasswordResetRoute` ainda não tem página real; até a TASK-036, o link "Esqueci minha senha" leva
  ao `NotFoundPage` em produção (mesmo risco que `LoginRoute` tinha documentado antes desta task).
- `AppRouter` continua com `AlwaysAllowAuthGuard` como default — a tela de login só se torna o
  ponto de entrada real do app quando a TASK-041 trocar o guard para `SessionAuthGuard` (ou
  equivalente) e resolver persistência de sessão entre reinícios do app.
- SSO/provedores (Google, Apple, corporate SSO) não fazem parte desta task — `signInWithProvider`
  continua retornando falha "não suportado" (TASK-173).

## Pendências

- Nenhuma pendência de código para o escopo desta task. Cadastro inicial (TASK-035) e recuperação
  de senha (TASK-036) são as próximas tasks do EPIC-04 e devem registrar suas próprias páginas nas
  rotas já pré-declaradas.

## Evidências

- `flutter analyze` → `No issues found!`
- `flutter test` → `00:25 +710: All tests passed!`

## Commit

Commit local único cobrindo implementação, testes, documentação e atualização do backlog.

## Push

Não realizado — sem autorização explícita nesta conversa (instrução do orquestrador: apenas
`git commit` local).

## Hash do commit

Ver seção "Commit" da resposta final (hash real do commit criado após esta documentação).

## Branch

`main`
