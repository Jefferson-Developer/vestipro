# TASK-166 — Realizar release MVP controlado — PROGRESSO (NÃO CONCLUÍDA)

**Data desta rodada:** 2026-09-06
**Status real:** 🔴 **Não concluída.** Trabalho preparatório de documentação feito; a release em si
(build de teste/produção liberado, validado em dispositivo real, com observabilidade confirmada e
dry-run de rollback executado) **não foi e não podia ser realizada** neste ambiente. Este arquivo
existe para deixar o estado real registrado, sem inventar uma conclusão que não aconteceu — por
isso, deliberadamente, **não há** um `TASK-166-...-CONCLUIDA.md`, o checkbox da TASK-166 em
`docs/tasks/TASKS.md` **permanece `[ ]`**, e o "Progresso: 165/220" **não foi alterado**.

## Por que a task não pôde ser concluída

Os critérios de aceite da TASK-166 exigem coisas que este ambiente de execução não tem meios de
fazer de forma genuína:

1. **Checklist de release 100% concluído** — não está. Ver
   `docs/release/mvp-release-checklist.md`: vários itens marcados 🔴, o mais grave sendo um
   **incidente de segurança ativo e pré-existente, não causado por esta task**: as Firestore
   Security Rules publicadas no projeto Firebase real `vestipro` estão em modo teste (liberação
   total de leitura/escrita para qualquer pessoa até 22/09/2026) — `docs/backlog/BACKLOG-003-*.md`.
   Isso por si só é um NO-GO absoluto para qualquer release, independentemente de qualquer outra
   condição.
2. **Testes 100% verdes** — não estão. `flutter test` rodado nesta sessão contra o commit `6a5d70d`
   confirma as mesmas 2 falhas já documentadas por TASK-165 (`test/app/bootstrap_test.dart`,
   `test/core/analytics/analytics_events_test.dart`), sem regressão nova, mas também sem correção.
3. **`npm audit --audit-level=high` limpo** — não está (BACKLOG-004, vulnerabilidade alta em
   `undici`, transitiva via SDKs Firebase de teste).
4. **Build de teste/produção rastreável a um pipeline verde específico** — o pipeline de CI/CD
   (TASK-165) existe no repositório, mas **nunca rodou de fato no GitHub Actions** (sem acesso remoto
   nesta sessão, mesmo em TASK-165); os secrets necessários e a proteção de branch ainda não foram
   cadastrados. Sem uma execução real do pipeline, não existe hoje nenhum "build oficial" a apontar.
5. **Validação manual em dispositivo/ambiente real por plataforma** — impossível neste sandbox
   (Windows, sem dispositivo Android/iOS físico anexado, sem acesso a Play Console/App Store
   Connect).
6. **App Check habilitado no(s) ambiente(s) de destino** — o código está pronto (TASK-032), mas o
   registro real no Firebase Console do projeto `vestipro` nunca foi feito (ação manual de infra,
   fora do alcance desta sessão).
7. **Dry-run real do plano de rollback** — o plano foi escrito (`docs/release/rollback-plan.md`),
   mas nenhuma ação real foi executada contra um ambiente de destino de produção (não há acesso a
   ele nesta sessão).

Dado isso, marcar o checkbox `[x]` ou criar um `-CONCLUIDA.md` seria uma afirmação falsa sobre o
estado do produto — especificamente sobre o item 1, que é uma vulnerabilidade de segurança real e
ativa em produção, não uma limitação apenas deste ambiente de execução.

## O que foi feito nesta rodada (preparatório, dentro do que era seguro fazer sem produção/push)

- **Levantamento honesto do estado real** de todos os pré-requisitos citados pela TASK-166
  (TASK-030/031/032, TASK-016/017/019, TASK-161/162/163/164/165), lendo cada `*-CONCLUIDA.md` e os
  itens de `docs/backlog/`.
- **Execução local real** (sem invenção de resultado) de:
  - `dart format --set-exit-if-changed .` → `Formatted 2317 files (0 changed)` — limpo.
  - `flutter analyze` → 12 issues, todas "info", nenhuma nova (mesmas já documentadas em TASK-164/165).
  - `flutter test` → 2943 testes, 2 falhas, as mesmas 2 já documentadas em TASK-165 — confirmação de
    que nada regrediu desde então, mas também de que nada foi corrigido.
- **`docs/release/mvp-release-checklist.md`** (novo) — checklist final de release consolidado,
  item a item, cruzando segurança/observabilidade/qualidade/builds/rollback/feature flags com o
  estado real do repositório e do projeto Firebase, com os critérios de go/no-go definidos
  explicitamente para uso em rodadas futuras.
- **`docs/release/rollback-plan.md`** (novo) — plano de rollback documentado (reversão de versão
  publicada por plataforma, desativação de feature flags via Remote Config sem novo deploy,
  identificação de impacto via Crashlytics/Performance/Analytics), com a ressalva explícita de que
  o dry-run real ainda não foi executado.

## O que falta e quem precisa agir

| Pendência | Quem precisa agir |
|---|---|
| **Reverter as Firestore Rules em modo teste no projeto `vestipro` real** (`BACKLOG-003`) — urgente, incidente de segurança ativo | Responsável de infraestrutura/backend com acesso ao Firebase Console/CLI autenticado do projeto real; `firebase deploy --only firestore:rules` |
| Corrigir os 2 testes que falham (`bootstrap_test.dart`, `analytics_events_test.dart`) | Próxima task de qualidade dedicada (decisão de negócio sobre os 3 eventos de analytics divergentes; investigação do `PushDeviceMapper` no bootstrap) |
| Resolver ou aceitar formalmente `BACKLOG-004` (vulnerabilidade alta `undici`) | Responsável técnico — decidir entre bump de major version (revalidado com Java/Emulator) ou aceite formal de risco documentado |
| Cadastrar secrets (`FIREBASE_OPTIONS_DART_BASE64`, `GOOGLE_SERVICES_JSON_BASE64`) e branch protection no GitHub, e rodar o pipeline de CI de verdade pela primeira vez | Responsável com acesso de administração ao repositório GitHub |
| Registrar Firebase App Check no Console do projeto `vestipro` (Play Integrity/App Attest/reCAPTCHA) e configurar enforcement Monitor→Enforce | Responsável de infraestrutura com acesso ao Firebase Console |
| Configurar assinatura de release Android real (hoje usa fallback de debug signing) | Responsável mobile/infra com acesso ao keystore de produção |
| Instalar o build gerado pelo pipeline em ao menos um dispositivo Android/iOS real e confirmar manualmente os fluxos críticos do MVP | Responsável mobile com acesso a dispositivo físico |
| Confirmar nos consoles reais (Crashlytics/Analytics/Performance) que o build candidato está de fato recebendo eventos | Responsável mobile/infra com acesso aos consoles do projeto real |
| Executar o dry-run real do plano de rollback (ex.: alterar `feature_insights_enabled` no Remote Config Console real e confirmar o efeito) | Responsável de infra/mobile com acesso ao Console do projeto real |

Só depois de todos os itens acima estarem resolvidos é que a TASK-166 pode ser reavaliada para
conclusão real, reexecutando o checklist em `docs/release/mvp-release-checklist.md`.

## Comandos executados nesta rodada (resultado real)

```
dart format --set-exit-if-changed .
→ Formatted 2317 files (0 changed) in 6.61 seconds.

flutter analyze
→ 12 issues found (todas "info", nenhuma nova).

flutter test
→ 2943 tests, 2943 -2 (2 falhas): test/app/bootstrap_test.dart, test/core/analytics/analytics_events_test.dart
```

## Push e deploy

Não realizados. Nenhum push ao remoto, nenhum deploy/release real, nenhuma ação contra o projeto
Firebase de produção nesta rodada — apenas leitura/análise e documentação local.
