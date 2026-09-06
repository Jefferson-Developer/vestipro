# Plano de Rollback — Release MVP VestiPro

**Referente a:** TASK-166 — Realizar release MVP controlado
**Status:** documento de processo elaborado nesta rodada (2026-09-06). **Dry-run real (execução
contra um ambiente de produção de fato) não foi realizado** — esta sessão não tem autorização nem
acesso a Play Console, App Store Connect, Firebase Hosting real ou ao projeto Firebase de produção.
O que segue é o procedimento que deve ser seguido e validado por quem tiver esse acesso, antes de
qualquer release real ser liberada (critério de aceite explícito da TASK-166).

## Princípios

- Rollback nunca deve ser improvisado durante um incidente: o procedimento abaixo deve já estar
  testado (dry-run) antes da primeira liberação real.
- Preferir reverter/mitigar sem novo deploy sempre que possível (feature flag via Remote Config) —
  é mais rápido e reduz o risco de introduzir um novo problema durante o próprio rollback.
- Nenhuma ação de rollback deve contornar RBAC/Security Rules/regras de preço — mesmas restrições de
  segurança valem em incidente.

## 1. Identificar o impacto rapidamente

1. Abrir o console do Crashlytics do projeto Firebase de destino, filtrar por versão do app
   (`versionName+versionCode`, hoje `1.0.0+1` em `pubspec.yaml`) igual à do build liberado.
   Verificar taxa de crash-free por sessão/usuário nas últimas horas.
2. Abrir o console do Firebase Performance Monitoring, comparar as métricas do build liberado
   (tempo de tela, HTTP/Firestore) contra a baseline documentada em
   `docs/tasks/TASK-164-otimizar-performance-CONCLUIDA.md`.
3. Abrir o Analytics (BigQuery export ou console), checar se os eventos comerciais mínimos (login,
   organização, cliente, produto, catálogo, pedido, sync, CRM, insight, relatório, offline pack)
   continuam sendo recebidos na taxa esperada — uma queda abrupta em um evento específico costuma
   indicar uma tela/fluxo quebrado, não apenas um crash.
4. Cruzar horário do início do problema com o histórico de deploys (pipeline de CI, TASK-165) e com
   o histórico de mudanças de Remote Config, para decidir se a causa mais provável é código (exige
   reverter build) ou configuração remota (feature flag — não exige novo deploy).

## 2. Mitigação sem novo deploy — feature flags (Remote Config)

- Toda flag usada para gatear uma funcionalidade de risco deve estar registrada em
  `FeatureFlagRegistry` (`lib/core/feature_flags/feature_flag_registry.dart`) com um `owner`
  responsável — ver `docs/architecture/feature-flags.md`.
- Para desativar uma funcionalidade sem novo deploy: no Firebase Console → Remote Config, alterar o
  valor do parâmetro (`feature_<modulo>_<nome>_enabled` → `false`) e publicar. O app já lê o valor
  do jeito certo (`FirebaseFeatureFlagService`, nunca acesso direto ao SDK pela feature) e
  `production` tem `minimumFetchInterval` de 1 hora — ou seja, o efeito não é instantâneo para toda
  a base instalada; para um incidente crítico, considerar também as opções da seção 3/4.
- Hoje (2026-09-06) a única flag de rollout temporário registrada é `feature_insights_enabled`
  (placeholder do atalho "Insights" em `AboutAppPage`) — ver checklist, seção 6. Não há, portanto,
  nenhuma flag de risco real protegendo uma funcionalidade de produção crítica ainda; a lista de
  flags "desligáveis em incidente" deve ser mantida atualizada aqui conforme o MVP crescer.
- Parâmetros como `config_report_export_max_local_rows` também podem ser ajustados via Remote Config
  para mitigar um problema de performance/carga sem deploy (ex.: reduzir o limite para forçar mais
  exportações a irem para a Cloud Function em vez do device).

## 3. Reverter uma versão publicada (build)

### Android (Play Console)

1. Play Console → app VestiPro → produção (ou trilha de teste correspondente) → Releases.
2. Se o rollout da versão problemática ainda estiver em progresso (rollout percentual), usar
   "Pausar rollout" imediatamente — interrompe a distribuição para novos usuários sem remover o app
   de quem já atualizou.
3. Para reverter de fato para a versão anterior, promover novamente o artefato (AAB) da última
   release estável conhecida como uma nova release (Play Console não permite "despublicar" e
   voltar automaticamente; o caminho suportado é publicar a versão anterior como um novo
   `versionCode` maior).
4. Cada release enviada precisa ser rastreável ao commit exato do pipeline (TASK-165, critério de
   aceite desta task) — antes de promover uma versão anterior, confirmar no histórico do CI qual
   commit gerou aquele AAB especificamente.

### iOS (App Store Connect) — quando aplicável

1. App Store Connect → app VestiPro → versão em revisão/lançada.
2. Se ainda em revisão, remover a submissão (Cancel this version) e submeter a build anterior.
3. Se já lançada, a Apple não permite rollback automático: é necessário submeter uma nova versão
   (com `versionCode` maior) contendo o build anterior/corrigido, sujeita a novo processo de revisão
   — dimensionar o tempo disso no plano de comunicação do incidente.

### Web (Firebase Hosting)

1. `firebase hosting:releases:list` no projeto de destino para listar releases anteriores.
2. `firebase hosting:rollback` reverte instantaneamente para a release anterior — esta é a única das
   três plataformas com rollback real e imediato sem novo build.

## 4. Critério de decisão: flag vs. rollback de build

- Problema isolado a uma funcionalidade específica e coberta por uma flag → desativar a flag
  (seção 2), monitorar, só então decidir se precisa também de rollback de build.
- Problema estrutural (crash no boot, regressão em fluxo crítico não coberto por flag, dado
  corrompido por bug de sync) → rollback de build (seção 3) tem prioridade sobre tentar mitigar via
  flag.
- Em caso de dúvida, tratar como estrutural (mais seguro reverter o build do que arriscar deixar o
  problema ativo tentando uma mitigação parcial).

## 5. Comunicação e registro

1. Abrir um registro do incidente (mesmo formato de `docs/backlog/BACKLOG-XXX-*.md` quando o
   problema não for corrigido no ato) descrevendo: sintoma, horário de início, versão afetada, ação
   de mitigação tomada, horário de resolução.
2. Após o rollback, confirmar nos consoles de Crashlytics/Performance/Analytics que os indicadores
   voltaram à baseline antes de encerrar o incidente.

## Status do dry-run (critério de aceite da TASK-166)

**Não executado nesta sessão.** Um dry-run real exigiria, no mínimo: uma flag de risco real ativa em
um ambiente de destino real, alterá-la de fato no Remote Config Console do projeto `vestipro`, e
confirmar o efeito observável no app — nenhuma dessas ações está disponível neste ambiente sandbox
(sem acesso ao Console do projeto de produção real). Isso permanece uma pendência explícita antes de
qualquer release ser liberada.
