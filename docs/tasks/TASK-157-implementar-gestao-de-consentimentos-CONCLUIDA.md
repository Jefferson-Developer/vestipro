# TASK-157 — Implementar gestão de consentimentos (CONCLUÍDA)

**Epic:** EPIC-20 — LGPD e Privacidade
**Depende de:** TASK-156 (política de privacidade e termos)

## Resumo

A feature `privacy` foi ampliada com consentimentos opcionais e específicos por finalidade,
mantidos separados do aceite obrigatório/versionado de política e termos. `ConsentRecord` representa
cada decisão como um evento imutável de concessão ou revogação, com organização, usuário,
finalidade e instante autoritativo do servidor. O histórico não é sobrescrito.

A tela autenticada `/org/:orgId/settings/privacy` agora apresenta separadamente localização e
marketing/novidades. Ambos iniciam desativados e usam o mesmo controle, no mesmo lugar e com o mesmo
número de passos, para conceder ou revogar. A tela informa o estado efetivo e a data/hora da decisão
mais recente, além de manter acesso aos documentos legais em uma rota própria.

`WatchConsentAccess` fornece um gate reativo para funcionalidades dependentes, como geolocalização.
Ele nunca libera a finalidade sem opt-in e emite `false` assim que um evento de revogação passa a ser
o vigente, sem depender de novo login.

## Agentes utilizados

- `flutter-senior-architect`: arquitetura, domínio, repositório, multi-tenant, Rules e testes.
- `flutter-ui-design-specialist`: hierarquia da tela, opt-in explícito, acessibilidade e equivalência
  entre concessão e revogação.

## Arquivos criados

- `lib/features/privacy/domain/entities/consent_record.dart`
- `lib/features/privacy/domain/repositories/consent_repository.dart`
- `lib/features/privacy/domain/usecases/consent_use_cases.dart`
- `lib/features/privacy/data/firestore_consent_repository.dart`
- `lib/features/privacy/presentation/consent_management_cubit.dart`
- `lib/features/privacy/presentation/privacy_and_consents_page.dart`
- `test/features/privacy/domain/consent_use_cases_test.dart`
- `test/features/privacy/presentation/privacy_and_consents_page_test.dart`

## Arquivos alterados

- `lib/features/privacy/privacy.dart`
- `lib/app/bootstrap.dart`
- `lib/core/navigation/app_route_paths.dart`
- `lib/core/navigation/app_router.dart`
- `lib/features/settings/presentation/pages/about_app_page.dart`
- `firestore.rules`
- `firestore-tests/firestore.rules.test.js`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

Fluxo feature-first/Clean Architecture: página -> Cubit -> `GrantConsent`/`RevokeConsent` -> contrato
`ConsentRepository` -> `FirestoreConsentRepository`. A seleção do evento vigente e o gate reativo
ficam no domínio, sem regra de negócio no widget. A composição com autenticação, organização e
Firestore reais permanece centralizada em `bootstrap.dart`.

## Regras de negócio implementadas

- Consentimentos opcionais nunca são assumidos: ausência de registro equivale a `false`.
- Localização e marketing são finalidades independentes.
- Conceder e revogar usam o mesmo switch e exigem uma única ação explícita.
- Cada mudança gera um registro novo e imutável; a mais recente define o estado efetivo.
- O gate de funcionalidades sensíveis acompanha o stream durante toda a atividade e reage à
  revogação imediatamente.
- O aceite geral de documentos legais continua separado dos consentimentos opcionais.

## Regras Firebase implementadas

`users/{userId}/consentRecords/{recordId}` aceita apenas `create` pelo próprio usuário, exige
membership ativo na organização declarada, finalidade conhecida, booleano de decisão e
`recordedAt == request.time`. Update/delete são negados. Leituras exigem simultaneamente o próprio
UID e membership ativo no tenant do registro. Foram adicionados casos positivos, imutabilidade,
outro usuário e cross-tenant no teste de Rules.

## Analytics implementado

Nenhum evento novo: decisões de consentimento são dados pessoais de conformidade e não foram
duplicadas em analytics.

## Crashlytics implementado

Nenhuma alteração. Falhas esperadas são convertidas para `Failure` e exibidas com retry.

## Impacto offline

A tela depende do snapshot/cache do SDK Firestore. A decisão é gravada como evento e o listener
reativo atualiza a UI e os consumidores; não foi criada persistência paralela que pudesse divergir da
trilha autoritativa. Uma funcionalidade sensível deve permanecer fechada diante de ausência/falha.

## Impacto multi-tenant

Todas as operações carregam e filtram `organizationId` e `userId`. Rules não confiam apenas no tenant
do payload: relêem a membership real e ativa. Testes de domínio e Rules cobrem isolamento entre
organizações e usuários.

## Testes criados

- concessão/revogação com finalidade e timestamp UTC;
- bloqueio sem opt-in;
- revogação emitindo desativação imediata;
- listagem isolada por organização e usuário;
- widget com finalidades e estado inicial claro;
- mesmo controle concedendo e revogando em um toque;
- Rules positivas/negativas, imutabilidade e isolamento cross-tenant/usuário.

## Comandos executados e resultados

- `dart format ...` e `dart format --output=none --set-exit-if-changed ...`: arquivos formatados; na
  verificação final, 0 alterações.
- `dart analyze lib/features/privacy`: sem problemas.
- `flutter analyze`: nenhum erro ou aviso da TASK-157; retornou status 1 por 12 infos preexistentes em
  arquivos de relatórios/dashboards fora do escopo.
- `flutter test test/features/privacy`: 12 testes passando.
- `flutter test test/core/navigation/app_router_test.dart`: 21 testes passando.
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test -- --runInBand"`, com o
  Java 21 do Android Studio adicionado ao `PATH` somente para o processo: os 3 testes da TASK-157
  passaram; a suíte total terminou com 140 passando e 9 falhas preexistentes fora do escopo
  (queries de orders/members e configuração dos testes de aggregates).

## Decisões técnicas

- Eventos append-only preservam todas as concessões e revogações, ao contrário de sobrescrever um
  único documento por finalidade.
- O timestamp persistido é do servidor para impedir forja do instante de auditoria.
- O gate reativo é genérico porque o módulo concreto de geolocalização/check-in pertence à
  EPIC-24 e ainda não existe no repositório.

## Riscos conhecidos e pendências

- A suíte global de Firestore Rules ainda não está verde por 9 falhas fora desta task; os 3 casos de
  consentimento passaram no mesmo run.
- Ao implementar geolocalização/check-in na EPIC-24, o serviço deve manter assinatura ativa em
  `WatchConsentAccess` e interromper coleta/uso ao receber `false` ou falha.

## Commit e push

Commit local no padrão `feat(privacy): implementa gestão de consentimentos (TASK-157)`. Push não
executado, conforme solicitação do lote.
