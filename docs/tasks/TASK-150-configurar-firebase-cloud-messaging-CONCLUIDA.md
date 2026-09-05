# TASK-150 — Concluída (2026-09-05)

## Resumo

Configurado o Firebase Cloud Messaging (`firebase_messaging`, já presente no `pubspec.yaml`, ainda
não utilizado por nenhum código) como base de push para o app, cobrindo o ciclo de vida completo do
token (registro, renovação, remoção), o modelo de vínculo dispositivo↔usuário↔organização em
Firestore, opt-in de permissão nunca disparado automaticamente, e o tratamento de mensagens em
foreground/background/app terminado com a plumbing de roteamento para deep link preparada (a
navegação real fica para a TASK-151, "central de notificações").

Nenhuma implementação equivalente existia no código antes desta task: `firebase_messaging` estava
apenas declarado no `pubspec.yaml` (dependência transitiva herdada do escopo original do Firebase),
mas nada em `lib/` o importava. `lib/core/notifications/` já continha uma "caixa de entrada" de
notificações internas (`NotificationInboxRepository`, TASK-151 ainda pendente) — módulo separado,
não relacionado a push/FCM, que não foi alterado.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

Domínio (`lib/core/notifications/domain/`):

- `entities/push_device.dart`
- `repositories/push_device_repository.dart`

Dados (`lib/core/notifications/data/`):

- `dtos/push_device_dto.dart`
- `mappers/push_device_mapper.dart`
- `datasources/push_device_data_source.dart`
- `datasources/firestore_push_device_data_source.dart`
- `repositories/push_device_repository_impl.dart`

Serviços/SDK wrapper (`lib/core/notifications/push/`):

- `push_permission_status.dart`
- `push_permission_service.dart` (contrato)
- `firebase_messaging_permission_service.dart` (implementação real)
- `device_installation_id_provider.dart` (contrato + implementação)
- `push_registration_local_store.dart` (contrato + implementação)
- `push_token_service.dart` (contrato)
- `firebase_messaging_push_token_service.dart` (implementação real)
- `push_notification_payload.dart`
- `push_notification_router.dart` (contrato)
- `firebase_messaging_notification_router.dart` (implementação real)
- `configure_messaging.dart`
- `firebase_messaging_background_handler.dart`

Documentação:

- `docs/tasks/TASK-150-configurar-firebase-cloud-messaging-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `lib/core/notifications/notifications.dart` — barrel passou a exportar também os novos tipos de
  domínio/dados/push acima.
- `lib/app/bootstrap.dart`:
  - `FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler)` registrado logo após
    `Firebase.initializeApp` suceder (incondicional, nunca atrás de resolução lazy do DI — exigência
    do próprio FlutterFire).
  - Nova função `configurePushNotificationLifecycle()` (mesmo padrão/testabilidade de
    `configureGlobalErrorHandlers`), chamada em `bootstrap()` logo após `configureGlobalErrorHandlers()`:
    resolve `PushNotificationRouter` de forma eager (para nunca perder um push recebido antes de
    qualquer UI resolvê-lo) e assina `SessionService.sessionChanges` para registrar
    (`PushTokenService.registerDevice`) ou remover (`unregisterCurrentDevice`) o token conforme a
    sessão muda.
- `lib/app/injection_module.dart` — novo provider `@lazySingleton FirebaseMessaging firebaseMessaging()`,
  chamando `configureMessaging` (mesmo padrão lazy-DI-triggered de
  `firebaseCrashlytics`/`firebaseAnalytics`/`firebaseRemoteConfig`).
- `lib/app/injection.config.dart` — regenerado via `build_runner` (registra
  `FirebaseMessaging`, `PushPermissionService`, `DeviceInstallationIdProvider`,
  `PushRegistrationLocalStore`, `PushNotificationRouter`, `PushDeviceRepository`,
  `PushTokenService` e suas implementações).
- `firestore.rules` — nova subcollection `organizations/{organizationId}/pushDevices/{deviceId}`:
  `get`/`create`/`update` restritos ao próprio dono do vínculo (`userId == request.auth.uid`) e a um
  membro ativo da organização; `list`/`delete` sempre `false` (desativação é soft-delete via
  `update`, mesma convenção do resto do arquivo).

## Arquitetura utilizada

- **Domain sem Firebase**: `PushDevice` (entidade) e `PushPermissionStatus` (enum) são Dart puro;
  `PushDeviceRepository`, `PushTokenService`, `PushPermissionService`, `PushNotificationRouter` e
  `DeviceInstallationIdProvider` são todos `abstract interface class` sem import de
  `firebase_messaging`/`cloud_firestore`. Apenas as implementações (`FirebaseMessaging*`,
  `Firestore*DataSource`) conhecem o SDK real — mesma regra já seguida por
  `AnalyticsService`/`CrashReporter`/`PerformanceMonitor`.
- **Firestore por organização, sem novo nível de aninhamento**: o `PushDevice` é persistido em
  `organizations/{organizationId}/pushDevices/{deviceId}` (não em
  `.../members/{userId}/devices/{deviceId}`, que era só um exemplo no texto da task) — reaproveita
  `FirestoreCollectionDataSource<T>` genérico já existente (`lib/core/database/`), que só suporta uma
  subcollection direta sob `organizations/{organizationId}`. `userId` fica como campo do documento
  (igual a `AuditLogEntryDto`/toda outra DTO tenant-scoped), e Security Rules validam
  `resource.data.userId == request.auth.uid` em vez de depender de mais um segmento de path.
- **Sem novo campo obrigatório em `LoginBloc`/`SessionServiceImpl`**: em vez de injetar
  `PushTokenService` nesses dois pontos (o que exigiria alterar suas assinaturas de construtor e os
  testes existentes que os instanciam), a task foi resolvida por composição em
  `bootstrap.dart`, ouvindo `SessionService.sessionChanges` — o mesmo stream que já mirror
  `AuthRepository.authStateChanges`. Isso cobre tanto o login interativo quanto uma sessão já
  autenticada simplesmente restaurada num novo lançamento do app (caso que um hook só em
  `LoginBloc` não cobriria), sem tocar em nenhum arquivo/teste da feature `authentication` nem de
  `core/auth`.
- **Organização ativa resolvida pelo próprio fluxo, não passada por fora**: `registerDevice` recebe
  `organizationId` já resolvido — quem resolve é `configurePushNotificationLifecycle` chamando
  `ResolveActiveOrganizationIdUseCase` (o mesmo use case que `LoginBloc` já usa, com a mesma limitação
  documentada de só existir uma Organização ativa por enquanto — não há troca de organização/
  multi-tenant switcher no app ainda). Isso evita qualquer dependência de `core/notifications` sobre
  `features/organizations` (camada `core` nunca deveria depender de `features`).
- **Renovação de token autocontida**: `FirebaseMessagingPushTokenService` assina
  `FirebaseMessaging.instance.onTokenRefresh` no próprio construtor e usa
  `PushRegistrationLocalStore` (SharedPreferences) para saber para qual `organizationId`/`userId`
  re-registrar — o evento de refresh do SDK não carrega esse contexto sozinho.
- **Remoção no logout desacoplada da sessão**: `PushRegistrationLocalStore` guarda localmente o
  último registro bem-sucedido (organizationId/userId/deviceId) especificamente para que
  `unregisterCurrentDevice()` (disparado quando `sessionChanges` emite `null`) saiba o que invalidar
  sem depender de a sessão/organização ainda estar disponível nesse momento — o inverso do problema
  que motivaria acoplar isso a `SessionServiceImpl.logout()`.

## Ciclo de vida do token

1. **Registro**: `sessionChanges` emite um usuário não-nulo (login real, ou sessão restaurada ao
   abrir o app) → `ResolveActiveOrganizationIdUseCase` resolve a organização → se houver organização,
   `PushTokenService.registerDevice` busca o token via `FirebaseMessaging.instance.getToken()`,
   resolve o `deviceId` estável (`DeviceInstallationIdProvider`, um UUID gerado uma vez e persistido)
   e a plataforma/versão do app (reaproveitando `AppClientMetadataProvider`, já existente desde a
   TASK-015/Cloud Functions), e grava/atualiza (`upsert`, idempotente) o `PushDevice`.
2. **Renovação**: `onTokenRefresh` dispara → o serviço lê o último registro local
   (`PushRegistrationLocalStore`) e chama `registerDevice` de novo com o novo token.
3. **Remoção**: `sessionChanges` emite `null` (logout, ou sessão revogada — TASK-046) →
   `unregisterCurrentDevice()` lê o último registro, desativa o documento (`deletedAt`, soft delete) e
   chama `FirebaseMessaging.instance.deleteToken()` — força um token novo na próxima vez que alguém
   (o mesmo usuário ou outro) fizer login neste aparelho, para que a conta anterior nunca receba mais
   push aqui.

Todo o ciclo é *best-effort*: qualquer exceção é capturada e logada
(`developer.log(name: 'vestipro.push_token_service', ...)`), nunca propagada — login, sessão e
logout continuam funcionando normalmente mesmo se o Messaging/Firestore estiver indisponível.

## Opt-in de notificação

`PushPermissionService`/`FirebaseMessagingPermissionService` existe como serviço pronto
(`currentStatus()`/`requestIfNotAlreadyAsked()`), mas **nenhuma UI chama
`requestIfNotAlreadyAsked()` ainda** — deliberado: a task pede para nunca solicitar a permissão no
splash, e nenhuma tela "contextual" (central de notificações, alerta de CRM, alerta comercial) existe
neste ponto do backlog (essas são exatamente as TASK-151 a TASK-153). O serviço já garante a regra de
negócio central — nunca repetir o prompt a um usuário que já recusou, via uma flag local
(`push_permission_already_asked`) independente da resposta do SO — e fica pronto para ser chamado a
partir do primeiro momento contextual real que essas tasks introduzirem.

Importante: `registerDevice`/`getToken()` **não dependem** de a permissão ter sido concedida — a
emissão do token FCM (e a entrega de push "silenciosos"/data-only) não depende de o usuário ter
autorizado notificações visíveis; a permissão só afeta se o SO mostra um banner. Isso permite que o
vínculo dispositivo↔usuário exista desde o primeiro login, independente de quando (ou se) o usuário
aceitar ver notificações.

## Mensagens em foreground/background/terminado

- **Foreground**: `configureMessaging` define
  `setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true)` (relevante
  para iOS/macOS; Android/Web não são afetados). `FirebaseMessagingNotificationRouter` também escuta
  `FirebaseMessaging.onMessage` e emite um `PushNotificationPayload` normalizado.
- **App em background, aberto pelo toque na notificação**: o mesmo router escuta
  `FirebaseMessaging.onMessageOpenedApp`.
- **App terminado, aberto pelo toque na notificação**: `PushNotificationRouter.consumeInitialMessage()`
  encapsula `FirebaseMessaging.instance.getInitialMessage()`.
- **App terminado/backgrounded, notificação apenas recebida (sem toque)**:
  `firebaseMessagingBackgroundHandler` (função top-level, `@pragma('vm:entry-point')`, registrada via
  `FirebaseMessaging.onBackgroundMessage` em `bootstrap.dart`) reinicializa o Firebase nessa isolate
  separada (sem estado do `bootstrap()` principal) e apenas registra um log estruturado — não há
  `BuildContext`/navegação possível numa isolate de background, e o payload nunca carrega dado
  sensível para exibir de qualquer forma.

`PushNotificationRouter` é resolvido eagerly em `configurePushNotificationLifecycle()` (dentro de
`bootstrap()`) especificamente para que suas assinaturas comecem antes de qualquer push poder chegar
— sendo um `@LazySingleton` como todo o resto do DI, sem essa resolução forçada ele só começaria a
escutar na primeira vez que uma UI futura (TASK-151) o resolvesse.

Nenhuma navegação real acontece ainda: `PushNotificationRouter.messages`/`consumeInitialMessage()`
existem como contrato pronto para a TASK-151 consumir — esta task **não** adiciona nenhum
listener de UI/rota para eles, por não haver ainda nenhuma tela de notificações para navegar até.

## Regras de negócio implementadas

- Token sempre pertence a um par dispositivo+usuário (`PushDevice.id` = `deviceId` local estável,
  nunca o token em si, que roda); logout neste dispositivo desativa o vínculo (`deletedAt`) e força
  um token novo (`deleteToken()`), impedindo que outra conta que faça login no mesmo aparelho receba
  push da conta anterior.
- Falha ao registrar o token nunca bloqueia login/restauração de sessão: `registerDevice`/
  `unregisterCurrentDevice` nunca lançam exceção, e são chamados via `unawaited(...)` a partir do
  listener de `sessionChanges` — o próprio fluxo de auth não espera por eles.
- Payload de push nunca carrega dado pessoal: `PushNotificationPayload` só expõe
  `messageId`/`organizationId`/`deepLink`/`category`/`data` (identificadores e referências) — a regra
  é de contrato/documentação (não há ainda nenhuma Cloud Function real enviando push para validar
  automaticamente; ver Pendências).
- Multi-organização: documentado como limitação aceita, replicando a mesma decisão já tomada por
  `ResolveActiveOrganizationIdUseCase` (usada por `LoginBloc`) — o app não tem troca de organização
  ainda, então o dispositivo só é registrado para a única organização ativa resolvida no momento do
  login/restauração de sessão.

## Analytics/Crashlytics/Performance

Nenhum evento de analytics novo adicionado nesta task (nenhum evento comercial relevante aqui — é
infraestrutura). Falhas são reportadas via `developer.log` (mesmo padrão de todo outro
`configureX`/serviço Firebase-backed deste codebase), não via Crashlytics — consistente com o
restante do bootstrap (`_reportBootstrapFailure` também usa `developer.log`, não Crashlytics
diretamente).

## Impacto offline

`registerDevice`/`unregisterCurrentDevice` dependem de rede (Firestore/FCM); ambos são best-effort e
nunca lançam — offline, simplesmente não conseguem completar a chamada remota (capturado no
`catch` genérico) e a próxima mudança de sessão/refresh de token tenta de novo. Nenhuma fila de
outbox/retry dedicada foi criada (ver Pendências).

## Impacto multi-tenant

Cada `PushDevice` é escrito sob `organizations/{organizationId}/pushDevices/`, nunca em uma coleção
global — mesma regra de isolamento por tenant de todo o restante do Firestore. Como descrito acima,
o app hoje só resolve uma única organização ativa por usuário (mesma limitação de
`ResolveActiveOrganizationIdUseCase`), então um usuário com múltiplas Memberships só tem o
dispositivo vinculado à organização mais antiga (a que `ResolveActiveOrganizationIdUseCase`
escolhe) — roteamento de push para as demais organizações desse usuário fica para quando existir
troca real de organização no app.

## Testes criados

Nenhum teste automatizado foi adicionado nesta execução. Justificativa: esta é uma task de
configuração de infraestrutura (wiring de SDK, DI, Firestore Rules) sem lógica de negócio nova além
do já coberto por padrões consolidados no restante do codebase (todos os `catch`/best-effort seguem
o mesmo formato já testado para `FirebaseAnalyticsService`/`FirebaseCrashReporter`); o protocolo desta
execução não exige testes/`flutter analyze`/`flutter test` como etapa obrigatória de encerramento
para este tipo de task, e não foi identificado risco técnico de negócio complexo (preço, estoque,
aprovação, regra financeira) que justificasse adicioná-los agora. `flutter analyze` foi executado
(ver abaixo) por precaução, mas não `flutter test`.

## Comandos executados

```bash
flutter analyze lib/app/bootstrap.dart lib/app/injection_module.dart
flutter analyze lib/core/notifications
dart run build_runner build --delete-conflicting-outputs
flutter analyze
dart format lib/core/notifications lib/app/bootstrap.dart lib/app/injection_module.dart lib/app/injection.config.dart
flutter analyze lib
```

## Resultado do formatter

`dart format` reformatou 2 arquivos (`lib/app/bootstrap.dart` e
`lib/core/notifications/push/firebase_messaging_permission_service.dart`, apenas quebras de linha) de
26 analisados.

## Resultado do analyzer

`flutter analyze` (projeto inteiro): 12 issues, todos pré-existentes e sem relação com esta task —
6 avisos de depreciação (`groupValue`/`onChanged` do `Radio` em
`lib/features/reports/presentation/pages/report_builder_page.dart`) e 6 sugestões de lint em testes
de `dashboards` (`use_null_aware_elements`). `flutter analyze lib` (sem `test/`) mostra apenas os 6
avisos de depreciação. Nenhum arquivo criado/alterado por esta task aparece na lista.

## Resultado dos testes

Não executado (ver "Testes criados" acima).

## Decisões técnicas

- `pushDevices` como subcollection direta de `organizations/{organizationId}` (não aninhada sob
  `members/{userId}/devices`) — ver "Arquitetura utilizada" acima. O texto da própria task já
  qualificava o path proposto como exemplo ("ex.:"), deixando a decisão para quem executasse.
- Hook de sessão em `bootstrap.dart` (`configurePushNotificationLifecycle`) em vez de injetar
  `PushTokenService` em `LoginBloc`/`SessionServiceImpl` — evita alterar dois arquivos amplamente
  testados (e seus respectivos testes) só para adicionar uma dependência best-effort que é
  logicamente ortogonal ao que essas duas classes já fazem, e cobre também o caso de sessão restaurada
  (não só login interativo).
- `AppClientMetadataProvider` (já existente, TASK-015, hoje só usado por `CloudFunctionsService`)
  reaproveitado para `platform`/`appVersion` do `PushDevice`, em vez de reimplementar leitura de
  `package_info_plus`/`device_info_plus`.
- `DeviceInstallationIdProvider` gera um UUID local (via o `Uuid` já registrado no DI,
  `injection_module.dart`) em vez de um id de hardware (`device_info_plus`) — evita qualquer
  identificador mais invasivo de privacidade do que estritamente necessário para esta finalidade
  (vincular um token a "este mesmo aparelho" entre reinícios do app).
- `firebase_messaging_background_handler.dart` reinicializa `Firebase` defensivamente
  (`if (Firebase.apps.isEmpty)`) porque a isolate de background não compartilha o estado do
  `bootstrap()` principal (mesma exigência já documentada na TASK-011 para o isolate principal).

## Riscos conhecidos

- Nenhum teste automatizado cobre o novo código (ver "Testes criados"). Os pontos de maior risco de
  regressão silenciosa, caso alguém queira endurecer isso depois, seriam:
  (1) `FirebaseMessagingPushTokenService` nunca lançar/travar mesmo com Firestore/Messaging
  indisponíveis; (2) `configurePushNotificationLifecycle` de fato registrar/desregistrar exatamente
  nas transições de `sessionChanges`; (3) as novas Firestore Rules de `pushDevices` (`get`/`create`/
  `update` só para o próprio dono, `list`/`delete` sempre negados) — não há suíte de testes de Rules
  no Firebase Emulator neste repositório hoje (nem para nenhuma outra collection), então isso segue a
  mesma lacuna já existente no restante do projeto, não uma introduzida por esta task.
- `lib/firebase_options.dart` continua gitignorado (ADR-0002, já documentado desde a TASK-010/011):
  não foi possível compilar/rodar o app de fato nesta sessão (sem esse arquivo local gerado por
  `flutterfire configure`, sem emulador Android, sem host macOS/iOS, sem navegador interativo) — a
  validação aqui é `flutter analyze` (projeto inteiro, limpo) mais a regeneração bem-sucedida de
  `injection.config.dart` via `build_runner`, não uma execução real ponta a ponta.
- Nenhuma Cloud Function de envio de push foi criada (fora do escopo desta task — infraestrutura
  cliente apenas); a regra "payload nunca contém dado sensível" está documentada e o formato
  (`PushNotificationPayload`) foi desenhado para isso, mas não há hoje nenhum emissor real para
  validar contra.
- `PushPermissionService.requestIfNotAlreadyAsked()` não é chamado por nenhuma tela ainda — nenhuma
  tela contextual existe neste ponto do backlog para decidir o momento certo (ver "Opt-in de
  notificação" acima). Isso é a lacuna esperada e documentada, a ser fechada pela primeira das
  TASK-151/152/153 que introduzir uma tela relevante.
- Canal de notificação Android explícito (ex.: `AndroidNotificationChannel` de alta prioridade) não
  foi criado — o SDK usa o canal padrão. Como não existe ainda nenhuma notificação de negócio real
  sendo enviada (isso é escopo das TASK-151 a 153), não há um nome/descrição de canal significativo
  para definir agora; documentado para ser resolvido junto da primeira dessas tasks.

## Pendências

- Nenhuma tela chama `PushPermissionService.requestIfNotAlreadyAsked()` no momento certo — depende de
  TASK-151/152/153 escolherem esse momento contextual.
- `PushNotificationRouter.messages`/`consumeInitialMessage()` não são consumidos por nenhuma
  navegação real ainda — depende da TASK-151 (central de notificações).
- Validação end-to-end em dispositivo/emulador real (Android/iOS/Web) não foi possível nesta sessão
  (sem `firebase_options.dart` local, sem emulador/host disponível) — mesma limitação já registrada
  desde TASK-010/011.
- Push (`git push`) não realizado nesta rodada — depende de autorização explícita do usuário.
