# BACKLOG-005 — Realizar release MVP controlado (🔴 bloqueada por acesso a produção)

**Origem:** TASK-166 — Realizar release MVP controlado (EPIC-21), movida do índice obrigatório de
`docs/tasks/TASKS.md` para o backlog em 2026-09-06, após duas rodadas confirmarem bloqueio real e
sem mudança de estado entre elas.

**Spec original (critérios de aceite completos):**
[`docs/tasks/TASK-166-realizar-release-mvp-controlado.md`](../tasks/TASK-166-realizar-release-mvp-controlado.md).

## Por que foi movida para o backlog

Os critérios de aceite da TASK-166 exigem ações que nenhum agente consegue fazer de dentro deste
repositório/sandbox — acesso a consoles de produção, credenciais reais e dispositivos físicos. Não é
um problema de implementação, é um problema de acesso. Manter a task no índice obrigatório apenas
bloqueava a fila sequencial sem nenhuma chance real de progresso a cada rodada.

1. **Incidente de segurança ativo em produção** — Firestore Security Rules do projeto Firebase real
   `vestipro` publicadas em modo teste (liberação total de leitura/escrita até 22/09/2026). Ver
   [BACKLOG-003](BACKLOG-003-reverter-firestore-rules-modo-teste.md). NO-GO absoluto por si só,
   independente de qualquer outro critério.
2. **Testes não 100% verdes** — 2 falhas conhecidas e já documentadas em TASK-165
   (`test/app/bootstrap_test.dart`, `test/core/analytics/analytics_events_test.dart`), sem regressão
   nova, mas sem correção.
3. **`npm audit --audit-level=high` não limpo** — ver
   [BACKLOG-004](BACKLOG-004-vulnerabilidade-alta-undici-testes-firebase-js.md).
4. **Pipeline de CI/CD (TASK-165) nunca rodou de fato no GitHub Actions** — faltam secrets
   (`FIREBASE_OPTIONS_DART_BASE64`, `GOOGLE_SERVICES_JSON_BASE64`) e branch protection cadastrados.
5. **Firebase App Check não registrado no Console real** do projeto `vestipro` (código pronto desde
   TASK-032, falta só o cadastro manual).
6. **Assinatura de release Android** ainda usa fallback de debug signing — falta keystore de
   produção.
7. **Validação manual em dispositivo real** (Android/iOS) e **confirmação de observabilidade real**
   (Crashlytics/Analytics/Performance recebendo eventos do build candidato) — impossíveis neste
   sandbox, sem dispositivo físico nem acesso aos consoles reais.
8. **Dry-run real do plano de rollback** — o plano foi escrito
   ([`docs/release/rollback-plan.md`](../release/rollback-plan.md)), mas nunca executado contra um
   ambiente real.

## O que já existe e pode ser reaproveitado quando isto for retomado

- [`docs/release/mvp-release-checklist.md`](../release/mvp-release-checklist.md) — checklist final
  de release item a item, com critérios de go/no-go já definidos.
- [`docs/release/rollback-plan.md`](../release/rollback-plan.md) — plano de rollback documentado.

## Quem precisa agir (pré-requisito para reabrir esta task)

| Pendência | Quem precisa agir |
|---|---|
| Reverter as Firestore Rules em modo teste no projeto `vestipro` real ([BACKLOG-003](BACKLOG-003-reverter-firestore-rules-modo-teste.md)) — urgente | Infra/backend com acesso ao Firebase Console/CLI autenticado do projeto real |
| Corrigir os 2 testes que falham (`bootstrap_test.dart`, `analytics_events_test.dart`) | Task de qualidade dedicada |
| Resolver ou aceitar formalmente [BACKLOG-004](BACKLOG-004-vulnerabilidade-alta-undici-testes-firebase-js.md) | Responsável técnico |
| Cadastrar secrets e branch protection no GitHub, rodar o pipeline de CI pela primeira vez | Responsável com acesso admin ao repositório GitHub |
| Registrar Firebase App Check no Console real (Play Integrity/App Attest/reCAPTCHA) | Infra com acesso ao Firebase Console |
| Configurar assinatura de release Android real (keystore de produção) | Mobile/infra com acesso ao keystore |
| Instalar o build em ao menos um dispositivo real e validar manualmente os fluxos críticos | Mobile com acesso a dispositivo físico |
| Confirmar nos consoles reais que o build candidato recebe eventos | Mobile/infra com acesso aos consoles do projeto real |
| Executar o dry-run real do plano de rollback | Infra/mobile com acesso ao Console do projeto real |

## Como reabrir

Depois que os pré-requisitos acima estiverem resolvidos (em especial o BACKLOG-003, que é a
prioridade máxima), promova este item de volta a uma TASK-XXX formal em `docs/tasks/TASKS.md`
(reaproveitando a spec original em `docs/tasks/TASK-166-realizar-release-mvp-controlado.md`) e
reexecute o checklist em `docs/release/mvp-release-checklist.md` do zero.
