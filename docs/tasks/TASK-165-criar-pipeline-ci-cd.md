# TASK-165 — Criar pipeline CI/CD

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Status:** ⬜ Pendente
**Depende de:** TASK-008 (qualidade estática, comandos de formatter/analyzer a automatizar),
TASK-009 (estrutura inicial de testes), TASK-161 (testes unitários de domínio, cuja cobertura o
pipeline deve validar e publicar)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Automatizar `dart format`, `flutter analyze`, `flutter test` e o build por ambiente em um pipeline
de CI/CD, bloqueando qualquer PR quando os quality gates falharem — quinto pilar do checklist de
qualidade que antecede o release do MVP (TASK-166).

## Escopo técnico

- Criar workflow de CI executando, em toda PR: `dart format --set-exit-if-changed .`,
  `flutter analyze`, `flutter test`, `flutter test --coverage`.
- Integrar `firebase emulators:exec "flutter test integration_test"` (TASK-162) como etapa
  obrigatória do pipeline para os fluxos críticos (auth, pedido, sincronização, precificação).
- Configurar builds por ambiente (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`) com
  `flutter build web` e `flutter build appbundle` como etapas de verificação — build quebrado bloqueia
  o merge.
- Bloquear merge quando qualquer quality gate falhar (formatter, analyzer, testes unitários, testes
  de integração, build).
- Validar dependências vulneráveis/desatualizadas como etapa do pipeline.
- Publicar o relatório de cobertura de testes como artefato do pipeline (evidência de TASK-161).

## Regras de negócio e restrições

- Nenhuma branch protegida pode receber merge com analyzer, testes ou build quebrados.
- Pipeline nunca usa credenciais/segredos de produção — apenas Emulator Suite e ambientes de
  dev/staging.
- Pipeline deve ser reproduzível localmente pelo mesmo conjunto de comandos documentado em
  `AGENTS.md`.

## Testes obrigatórios

- Validar (execução real do pipeline) que uma PR com `dart format` pendente é bloqueada.
- Validar que uma PR com `flutter analyze` ou `flutter test` falhando é bloqueada.
- Validar que a etapa de `firebase emulators:exec` roda e reporta falha corretamente quando um teste
  de integração quebra.
- Validar que os três builds por ambiente (`dev`, `staging`, `prod`) são executados/verificados no
  pipeline.
- Validar que o relatório de cobertura é gerado e anexado como artefato da execução.

## Critérios de aceite

- PR com qualquer quality gate falhando (format, analyze, testes unitários, testes de integração,
  build) é automaticamente bloqueada.
- Pipeline roda de ponta a ponta sem intervenção manual em uma PR limpa, incluindo os testes de
  Emulator Suite.
- Builds por ambiente (dev/staging/prod) são validados no pipeline antes do merge.
- Relatório de cobertura e resultados de teste ficam disponíveis como evidência de cada execução.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
