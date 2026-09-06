# TASK-159 — Concluída (2026-09-05)

## Resumo

Implementado o fluxo de exclusão global da conta, com confirmação textual em uma segunda etapa,
exigência server-side de autenticação realizada nos últimos cinco minutos, anonimização de histórico,
remoção de dados pessoais dispensáveis e limpeza completa do dispositivo.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

- `functions/src/privacy/account-deletion.ts`
- `functions/test/privacy/account-deletion.test.ts`
- `lib/features/privacy/data/account_deletion_local_cleaner.dart`
- `lib/features/privacy/data/firebase_account_deletion_repository.dart`
- `lib/features/privacy/domain/entities/account_deletion.dart`
- `lib/features/privacy/domain/repositories/account_deletion_repository.dart`
- `lib/features/privacy/domain/usecases/request_account_deletion.dart`
- `lib/features/privacy/presentation/account_deletion_cubit.dart`
- `test/features/privacy/data/account_deletion_local_cleaner_test.dart`
- `test/features/privacy/domain/request_account_deletion_test.dart`

## Arquivos alterados

- `functions/src/index.ts`
- `lib/app/bootstrap.dart`
- `lib/core/database/app_database.dart`
- `lib/features/privacy/presentation/privacy_and_consents_page.dart`
- `lib/features/privacy/privacy.dart`
- `test/features/privacy/presentation/privacy_and_consents_page_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

Clean Architecture feature-first: UI → Cubit → `RequestAccountDeletion` → contrato de repositório →
Cloud Function. A limpeza local usa um contrato separado e coordena Drift, ciclo de push e sessão.
Toda decisão destrutiva, inclusive titularidade e autenticação recente, permanece no backend.

## Regras de negócio implementadas

- Frase `EXCLUIR MINHA CONTA` obrigatória após abrir o diálogo destrutivo.
- Login deve ter ocorrido há no máximo cinco minutos; senha nunca é enviada à Function.
- A conta é excluída globalmente em todas as organizações com vínculo ativo.
- A operação é bloqueada antes de qualquer mutação se a pessoa for o único `OWNER` ativo em qualquer
  organização.
- Clientes e registros de terceiros nunca são excluídos em cascata.
- Pedidos, oportunidades e atividades permanecem no histórico com identificador pseudonimizado e o
  rótulo “Vendedor removido”.

### Dados retidos

- Pedidos e documentos fiscais: retidos por cinco anos após o fato gerador ou término contratual,
  com base em obrigação legal/contratual (LGPD, art. 7º, II); a identidade ativa é substituída por
  identificador pseudonimizado.
- Trilha administrativa de auditoria: retida por cinco anos após o evento para exercício regular de
  direitos (LGPD, art. 7º, VI), sem nome/e-mail ativo do titular.
- Uma ordem legal de preservação pode suspender o descarte ao fim do prazo; a política configurável e
  sua automação pertencem à TASK-160.

## Regras Firebase implementadas

A callable `requestAccountDeletion` deriva o usuário do token, valida vínculo e login recente,
remove dados próprios, revoga tokens, apaga a identidade no Firebase Auth e grava audit log em cada
tenant afetado. Admin SDK é usado; nenhuma Security Rule foi enfraquecida.

## Analytics implementado

Nenhum evento de Analytics foi criado, para não emitir identificadores durante um fluxo de
eliminação de dados pessoais. A evidência necessária fica no audit log restrito.

## Crashlytics implementado

Sem captura adicional de dados pessoais. Falhas são devolvidas pelos contratos existentes sem logar
senha, frase ou conteúdo pessoal.

## Impacto offline

Após sucesso remoto, todas as tabelas Drift são esvaziadas em transação, o registro/token de push do
dispositivo é removido e a sessão/secure storage é limpa. Exclusão não é enfileirada offline: exige
backend disponível para não produzir estado parcial.

## Impacto multi-tenant

Todos os vínculos ativos do usuário são descobertos server-side. O bloqueio de último OWNER é
avaliado em cada tenant antes da primeira mutação, e cada organização recebe auditoria própria.

## Testes criados

- Function/Emulator: anonimização e preservação de terceiros; remoção de RBAC/push/dados pessoais;
  bloqueio do único OWNER; frase exata; autenticação recente; auditoria da retenção.
- Dart: validação do caso de uso, limpeza posterior ao sucesso, limpeza física de caches/cursores
  Drift e confirmação em duas etapas na UI.

## Comandos executados

- `dart format --set-exit-if-changed <arquivos da task>`
- `dart analyze lib/features/privacy lib/core/database/app_database.dart lib/app/bootstrap.dart test/features/privacy`
- `flutter test test/features/privacy`
- `flutter analyze`
- `flutter test`
- `npm run build`
- `npm run lint`
- `firebase emulators:exec --only firestore "npm test -- --runInBand test/privacy/account-deletion.test.ts"`

## Resultado do formatter

Arquivos da task formatados; verificação final sem alterações.

## Resultado do analyzer

Escopo da task sem problemas. A análise global encontrou 12 infos preexistentes (APIs `Radio`
depreciadas e sugestões `use_null_aware_elements`), sem erro relacionado à TASK-159.

## Resultado dos testes

- Feature privacy: 17 testes passando.
- Function no Firestore Emulator: 4 testes passando.
- Build TypeScript e ESLint: sucesso.
- Suíte Flutter global: 2 falhas preexistentes em `bootstrap_test.dart` e
  `analytics_events_test.dart`; os demais 2.919 testes passaram. As falhas não tocam arquivos ou
  comportamento da TASK-159.

## Decisões técnicas

- Identificador histórico é hash SHA-256 truncado, não o UID ativo.
- O backend valida todos os tenants antes de mutar para evitar exclusão parcial por último OWNER.
- Exclusão local ocorre somente depois da confirmação de sucesso do servidor.

## Riscos conhecidos

A automação do descarte ao final dos prazos de cinco anos será coberta pela TASK-160. Coleções
futuras que adicionem novos campos pessoais precisam entrar no inventário da Function.

## Pendências

Nenhuma pendência dentro do escopo da TASK-159.

## Evidências

Implementação, testes unitários/widget e execução no Firestore Emulator registrados neste commit.

## Commit

`feat(privacy): implementa exclusão de conta e dados (TASK-159)`

## Push

Não realizado, conforme solicitado.

## Hash do commit

Preenchido após o commit local.

## Branch

`main`
