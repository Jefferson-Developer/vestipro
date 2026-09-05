# TASK-158 — Implementar exportação de dados pessoais (CONCLUÍDA)

**Epic:** EPIC-20 — LGPD e Privacidade
**Depende de:** TASK-013 (Cloud Firestore)

## Resumo

Foi implementado o fluxo de portabilidade dos dados pessoais do usuário autenticado. A solicitação
é criada por uma callable, processada de forma assíncrona por trigger do Firestore, armazenada como
JSON no Storage e refletida na tela de Privacidade pelos estados solicitado, processando, pronto,
expirado ou falha. Quando o pacote fica pronto, o usuário recebe uma notificação interna e pode
obter um link temporário emitido somente após nova validação autenticada de titularidade.

O pacote usa uma lista explícita de campos do perfil, do próprio vínculo, de consentimentos,
aceites, atividades e eventos de auditoria do solicitante. Dados de outros usuários e documentos de
clientes não são consultados nem serializados.

## Agentes utilizados

- `flutter-senior-architect`: arquitetura feature-first, Functions, Firestore/Storage Rules,
  isolamento por usuário/tenant, auditoria e testes.
- `flutter-ui-design-specialist`: estados do processamento, ação principal, feedback de erro e
  integração responsiva com a tela existente.

## Arquivos criados

- `functions/src/privacy/personal-data-export.ts`
- `functions/test/privacy/personal-data-export.test.ts`
- `lib/features/privacy/domain/entities/personal_data_export.dart`
- `lib/features/privacy/domain/repositories/personal_data_export_repository.dart`
- `lib/features/privacy/domain/usecases/personal_data_export_use_cases.dart`
- `lib/features/privacy/data/firestore_personal_data_export_repository.dart`
- `lib/features/privacy/presentation/personal_data_export_cubit.dart`
- `test/features/privacy/presentation/personal_data_export_cubit_test.dart`
- `docs/tasks/TASK-158-implementar-exportacao-de-dados-pessoais-CONCLUIDA.md`

## Arquivos alterados

- `functions/src/index.ts`
- `firestore.rules`
- `firestore.indexes.json`
- `firestore-tests/firestore.rules.test.js`
- `storage.rules`
- `storage-tests/storage.rules.test.js`
- `lib/app/bootstrap.dart`
- `lib/features/privacy/privacy.dart`
- `lib/features/privacy/presentation/privacy_and_consents_page.dart`
- `test/features/privacy/presentation/privacy_and_consents_page_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

Flutter segue página → Cubit → casos de uso → contrato de repositório → implementação
Firestore/Cloud Functions. No backend, `requestPersonalDataExport` autentica e registra o pedido;
`processPersonalDataExportRequested` dispara o processador idempotente; e
`getPersonalDataExportDownloadUrl` revalida titularidade, estado e expiração antes de emitir um link
de quinze minutos, nunca além das 24 horas do pacote.

## Regras de negócio, segurança e auditoria

- Somente o próprio UID solicita, acompanha e baixa seu pacote.
- Membership ativa é validada no backend para a organização da solicitação.
- A serialização usa allowlist de campos e queries filtradas pelo UID do titular.
- Pacotes duram 24 horas; links emitidos duram no máximo 15 minutos.
- Clientes não criam nem alteram solicitações ou arquivos diretamente.
- Solicitação e conclusão geram eventos no audit log central.
- Conclusão gera notificação interna com deep link para Privacidade.
- O processador tolera repetição do trigger nos estados `requested` e `processing`.

## Impacto offline e multi-tenant

A geração exige backend e não promete operação offline. O status é observado pelo cache/stream do
Firestore, sem Outbox paralela. A organização é validada por membership ativa e todas as coleções
organizacionais consultadas usam o tenant da solicitação, enquanto o UID autenticado define o
sujeito dos dados.

## Testes e validações

- `flutter test test/features/privacy`: 13 testes passando, incluindo a sequência solicitado →
  processando → pronto.
- `npm run build` em `functions`: TypeScript compilado sem erros.
- `npm run lint` em `functions`: ESLint sem erros.
- Teste da Function no Firestore Emulator: 2 testes passando; cobre pacote exato do titular,
  exclusão de terceiro, auditoria de solicitação/conclusão, estado pronto, titularidade e expiração.
- Testes focados de Firestore Rules no Emulator: 3 passando.
- Suíte de Storage Rules com Firestore + Storage Emulator: 37 passando, incluindo 2 casos novos de
  leitura exclusiva do titular, bloqueio anônimo e escrita negada.
- `flutter analyze`: nenhum diagnóstico novo da TASK-158; status 1 pelos mesmos 12 infos
  preexistentes em relatórios/dashboards.
- A suíte completa de Firestore Rules foi executada: os 3 casos da TASK-158 passaram; total de 143
  passando e 9 falhas preexistentes em orders, collection-group de members e configuração de
  aggregates.

## Decisões técnicas e riscos conhecidos

- JSON foi escolhido por ser legível, estruturado e adequado à portabilidade.
- O Storage também exige Firebase Auth do titular em acesso via SDK; a URL assinada só é emitida
  por callable autenticada e possui vida curta.
- A remoção física após 24 horas depende de política de lifecycle do bucket; mesmo antes dela, a
  callable recusa pacotes expirados e marca o status como `expired`.
- As 9 falhas legadas da suíte global de Firestore Rules permanecem fora do escopo desta task.

## Commit e push

Commit local no padrão `feat(privacy): implementa exportação de dados pessoais (TASK-158)`. Push
não executado, conforme solicitação do lote.
