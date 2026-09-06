# Checklist de Release MVP — VestiPro

**Referente a:** TASK-166 — Realizar release MVP controlado
**Status desta rodada de avaliação:** 🔴 **NO-GO** — checklist consolidado, mas com bloqueadores reais
não resolvidos. Ver `docs/tasks/TASK-166-realizar-release-mvp-controlado-PROGRESSO.md` para o
detalhamento de por que a task não foi marcada como concluída.
**Última avaliação:** 2026-09-06, commit avaliado: `6a5d70d` (HEAD no início desta rodada).

Este documento é o checklist final de release exigido pelo escopo da TASK-166. Ele deve ser
reexecutado (reavaliado item a item, não apenas reaproveitado) a cada tentativa real de release,
com a data e o commit atualizados.

## Como usar

- ✅ = verificado nesta sessão, com evidência abaixo.
- ⚠️ = implementado em código, mas não verificável neste ambiente (depende de acesso humano/infra
  fora do sandbox).
- 🔴 = bloqueador confirmado — impede o go/no-go independentemente do resto do checklist.

## 1. Segurança

| Item | Status | Evidência |
|---|---|---|
| `firestore.rules` (multi-tenant, RBAC) implementado e testado — TASK-030 | ✅ (no repositório) | `firestore.rules`, suíte `firestore-tests/` (positivo/negativo/multi-tenant, TASK-162) |
| `storage.rules` implementado e testado — TASK-031 | ✅ (no repositório) | `storage.rules`, suíte `storage-tests/` |
| **Regras publicadas no projeto Firebase real (`vestipro`) correspondem ao repositório** | 🔴 **BLOQUEADOR** | `docs/backlog/BACKLOG-003-reverter-firestore-rules-modo-teste.md`: as Firestore Rules publicadas em produção estão em **modo teste** (`allow read, write: if request.time < timestamp.date(2026, 9, 22)`) — liberação total de leitura/escrita para qualquer pessoa, autenticada ou não, em todas as organizações. Isso não foi corrigido por esta avaliação (exigiria `firebase deploy --only firestore:rules` contra produção real, fora da autorização desta sessão). **Nenhuma release pode prosseguir enquanto isso não for revertido por alguém com acesso ao projeto Firebase real.** |
| Firebase App Check ativado no código (TASK-032) | ✅ (no repositório) | `lib/core/security/configure_app_check.dart`, 7 testes unitários |
| App Check registrado no Firebase Console do projeto `vestipro` (Play Integrity/App Attest/reCAPTCHA) | ⚠️ pendente, ação manual de infra | `docs/tasks/TASK-032-configurar-firebase-app-check-CONCLUIDA.md`, seção "Pendências" — nunca foi registrado no Console |
| Enforcement (Monitor → Enforce) configurado por produto no Console | ⚠️ pendente, depende do item acima | idem |
| `npm audit --audit-level=high` limpo nos 3 subprojetos Node | 🔴 falha conhecida | `docs/backlog/BACKLOG-004-vulnerabilidade-alta-undici-testes-firebase-js.md` — vulnerabilidade alta (`undici`) em `firestore-tests/` e `storage-tests/`, sem fix disponível sem bump de major version ainda não revalidado |

## 2. Observabilidade

| Item | Status | Evidência |
|---|---|---|
| Crashlytics configurado (TASK-016) | ✅ código | `docs/tasks/TASK-016-configurar-firebase-crashlytics-CONCLUIDA.md` |
| Analytics configurado (TASK-017) | ✅ código | `docs/tasks/TASK-017-configurar-firebase-analytics-CONCLUIDA.md` |
| Performance Monitoring configurado (TASK-019) | ✅ código | `docs/tasks/TASK-019-configurar-firebase-performance-monitoring-CONCLUIDA.md` |
| Taxonomia de eventos de Analytics consistente com o código (`AnalyticsEvents`) | 🔴 falha confirmada nesta sessão | `flutter test test/core/analytics/analytics_events_test.dart` falha: teste espera 70 eventos, `AnalyticsEvents` real tem 73 — 3 eventos adicionados por alguma task posterior sem atualizar o teste de taxonomia congelada (achado já registrado por TASK-165, confirmado novamente aqui). |
| Observabilidade recebendo **dados reais** de um build candidato específico | 🔴 não verificável neste ambiente | Exige instalar um build real em dispositivo/ambiente real e observar os consoles Crashlytics/Analytics/Performance do projeto Firebase real — nenhuma dessas ações está disponível neste sandbox. |

## 3. Qualidade e testes

Comandos executados de fato nesta sessão (2026-09-06), contra o commit `6a5d70d`:

```
dart format --set-exit-if-changed .
→ "Formatted 2317 files (0 changed)" — limpo.

flutter analyze
→ 12 issues, todas "info" (6 depreciações RadioGroup/groupValue em
  lib/features/reports/presentation/pages/report_builder_page.dart, já documentadas em TASK-164;
  6 infos "use_null_aware_elements" em testes de dashboards). Sem erro/warning. Idêntico ao
  reportado por TASK-165.

flutter test
→ 2943 testes, 2 falhas pré-existentes (mesmas 2 já documentadas por TASK-165, nenhuma nova):
  - test/app/bootstrap_test.dart ("bootstrap initializes Firebase exactly once...")
  - test/core/analytics/analytics_events_test.dart ("exposes exactly the initial taxonomy...")
```

| Item | Status |
|---|---|
| TASK-161 (testes unitários de domínio) | ✅ concluída, mas suíte global tem 2 falhas hoje (acima) |
| TASK-162 (testes de integração com Emulator) | ✅ concluída no código; não executável neste ambiente (sem Java) |
| TASK-163 (testes offline/sincronização) | ✅ concluída no código |
| TASK-164 (performance) | ✅ concluída, métricas documentadas em `TASK-164-otimizar-performance-CONCLUIDA.md` |
| TASK-165 (pipeline CI/CD) | ✅ pipeline criado (`.github/workflows/ci.yml`), mas **nunca executado de fato no GitHub Actions** (sem acesso remoto nesta sessão nem em TASK-165); secrets `FIREBASE_OPTIONS_DART_BASE64`/`GOOGLE_SERVICES_JSON_BASE64` e branch protection ainda não cadastrados |
| `flutter test` 100% verde | 🔴 **BLOQUEADOR** — 2 falhas confirmadas nesta sessão (acima) |
| `firebase emulators:exec` (Rules/Functions/integration_test) verde | ⚠️ não executável neste ambiente (Java ausente) — mesma limitação de TASK-162/163/165 |

## 4. Builds finais rastreáveis ao pipeline

| Item | Status |
|---|---|
| Builds gerados pelo pipeline de CI (não manuais) | 🔴 não aplicável ainda — o pipeline (TASK-165) nunca rodou de verdade em CI; nenhum build "oficial" existe para apontar. Builds locais (`flutter build appbundle`/`web`) foram usados apenas para *validar* o pipeline durante TASK-165, nunca como candidatos de release. |
| Assinatura de release Android configurada | 🔴 pendente | `android/app/build.gradle.kts` usa fallback de debug signing hoje (comentário no próprio arquivo: "Release signing will be configured in the release pipeline task" — ou seja, esta task). Configuração de keystore de produção real não foi feita nesta sessão (exigiria credenciais reais de assinatura, fora do escopo seguro deste ambiente). |
| Validação manual em dispositivo/ambiente real por plataforma | 🔴 não executável neste ambiente | Sem dispositivo Android/iOS físico, sem loja de apps, sem acesso a Play Console/App Store Connect nesta sessão. |

## 5. Plano de rollback

Ver `docs/release/rollback-plan.md`. Documento elaborado nesta rodada; dry-run real (executar contra
ambiente de produção) **não realizado** — apenas o procedimento e os pontos de verificação estão
documentados, conforme autorização desta sessão (sem acesso a produção real).

## 6. Feature flags temporárias do MVP

| Flag | Owner | Criada em | Revisar até | Decisão nesta rodada |
|---|---|---|---|---|
| `feature_insights_enabled` | `flutter-senior-architect` | 2026-08-22 | 2026-11-22 | Manter — ainda é um placeholder aguardando o módulo real de Insights (EPIC-17), que ainda não existe no backlog atual (item 166 é anterior a EPIC-17 nas tasks futuras). Não remover antes do módulo real existir. Prazo de revisão (`2026-11-22`) ainda não vencido; nenhuma ação necessária agora. |

Demais entradas de `FeatureFlagRegistry` (`config_products_video_max_duration_seconds`,
`config_products_video_max_size_mb`, `config_catalog_home_sections_json`,
`config_report_export_max_local_rows`) são parâmetros operacionais de longo prazo, não flags de
rollout temporário — não fazem parte desta revisão de retirada.

## 7. Critérios de go/no-go definidos para o VestiPro

Uma release (build de teste ou produção) só pode avançar quando **todos** os itens abaixo forem
verdadeiros ao mesmo tempo:

1. As Security Rules publicadas no(s) ambiente(s) de destino são idênticas ao `firestore.rules`/
   `storage.rules` versionados no repositório (confirmado por leitura direta do Console ou
   `firebase firestore:rules:list`/exportação, não por suposição).
2. Firebase App Check está registrado e pelo menos em modo "Monitor" no ambiente de destino.
3. `npm audit --audit-level=high` retorna `EXIT=0` nos 3 subprojetos Node, ou a exceção está
   formalmente aceita e documentada com prazo de correção.
4. `flutter test` retorna 100% verde (nenhuma falha, mesmo pré-existente).
5. O pipeline de CI (`all-checks-passed`) rodou de verdade no GitHub Actions para o commit candidato
   e passou.
6. O build candidato foi instalado e verificado manualmente em ao menos um dispositivo/ambiente real
   por plataforma-alvo do release (Android, iOS quando aplicável, Web).
7. Crashlytics/Analytics/Performance Monitoring mostram, nos consoles reais, eventos recebidos do
   build candidato específico (não apenas configurados em teoria).
8. O plano de rollback (`docs/release/rollback-plan.md`) teve seu dry-run executado e validado no
   ambiente de destino real, com resultado registrado.
9. Nenhum item marcado 🔴 neste checklist permanece sem tratamento ou aceite formal e documentado de
   risco por quem tem autoridade para isso (ex.: responsável de produto/engenharia).

## Resultado desta avaliação (2026-09-06)

**NO-GO.** Itens 1, 3, 4, 5, 6, 7 e 8 dos critérios de go/no-go acima não estão satisfeitos hoje.
Destaque para o item 1: há um incidente de segurança ativo e não relacionado a esta task
(BACKLOG-003) que por si só já impede qualquer release de produção, independente de qualquer outro
item deste checklist.
