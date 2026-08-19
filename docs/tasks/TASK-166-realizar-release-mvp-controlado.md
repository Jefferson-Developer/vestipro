# TASK-166 — Realizar release MVP controlado

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Status:** ⬜ Pendente
**Depende de:** TASK-161 (testes unitários de domínio), TASK-162 (testes de integração com
Emulator), TASK-163 (testes offline e sincronização), TASK-164 (otimização de performance), TASK-165
(pipeline CI/CD) — todos os pilares de qualidade do MVP precisam estar concluídos e verdes antes
desta task

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Consolidar a primeira versão utilizável do VestiPro por meio de um checklist final de release —
segurança, observabilidade, testes, documentação e plano de rollback — antes de disponibilizar
builds de teste/produção. Esta é a task que fecha o MVP: deve ser tratada com o rigor de um
checklist de release real, não como "mais uma tela".

## Escopo técnico

- Consolidar checklist final de release cobrindo: segurança (Firestore/Storage Security Rules
  revisadas e testadas — TASK-030/TASK-031 —, Firebase App Check habilitado nos ambientes de destino
  — TASK-032), observabilidade (Crashlytics, Analytics e Performance Monitoring configurados e
  recebendo dados reais no build candidato — TASK-016/TASK-017/TASK-019), qualidade (testes
  unitários TASK-161, integração TASK-162, offline/sincronização TASK-163 todos verdes, performance
  TASK-164 com métricas documentadas, pipeline CI/CD TASK-165 verde).
- Validar builds finais por ambiente (`flutter build appbundle`, `flutter build ipa`,
  `flutter build web`) gerados a partir do pipeline (TASK-165) — nunca builds manuais fora do
  processo.
- Elaborar e documentar plano de rollback: como reverter uma versão publicada (Play Console/App
  Store/hosting Web), como desativar feature flags de risco via Remote Config sem novo deploy, como
  identificar rapidamente o impacto de um incidente (dashboards de Crashlytics/Performance).
- Definir e documentar critérios de "go/no-go" para liberar a build de teste/produção (ex.: taxa de
  crash-free acima do limite definido, zero regressão em fluxo crítico, RBAC e multi-tenant
  validados).
- Revisar as feature flags temporárias usadas durante o MVP (Remote Config) e decidir remoção ou
  manutenção, com responsável e data de revisão definidos.

## Regras de negócio e restrições

- Nenhum ambiente de produção pode ser liberado sem App Check habilitado e Security Rules validadas
  (positivo/negativo) para as entidades críticas.
- Nenhuma release pode seguir adiante com testes (unitários, integração, offline) quebrados ou
  pipeline vermelho.
- Plano de rollback deve existir antes da liberação, nunca ser improvisado após um incidente.
- Dados de observabilidade (Crashlytics/Analytics/Performance) devem estar realmente recebendo
  eventos do build candidato à release, não apenas configurados em teoria.

## Testes obrigatórios

- Execução completa e verde de toda a suíte: `dart format`, `flutter analyze`, `flutter test`,
  `flutter test --coverage`, `firebase emulators:exec "flutter test integration_test"`.
- Validação manual documentada dos builds finais (`flutter build appbundle`, `flutter build ipa`
  quando aplicável, `flutter build web`) instalados/executados em ao menos um dispositivo/ambiente
  real por plataforma.
- Teste de fumaça (smoke test) end-to-end dos fluxos críticos do MVP: login, criação de organização,
  cadastro de cliente, cadastro de produto com cor/grade, criação de pedido offline, sincronização
  com conflito, aprovação de desconto, geração de insight, exportação de relatório, RBAC negando ação
  não autorizada.
- Validação de que Crashlytics, Analytics e Performance Monitoring recebem eventos reais do build
  candidato.
- Simulação/dry-run do plano de rollback (ex.: desativar uma feature flag de risco via Remote Config
  e confirmar o efeito sem novo deploy).

## Critérios de aceite

- Checklist de release (segurança, observabilidade, testes, documentação, rollback) 100% concluído e
  registrado como evidência.
- Build de teste/produção liberada é rastreável até um commit/pipeline verde específico, sem builds
  manuais fora do processo.
- Plano de rollback documentado e validado por dry-run antes da liberação.
- MVP do VestiPro considerado utilizável de ponta a ponta pelos fluxos críticos, com observabilidade
  ativa monitorando o comportamento real pós-release.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
