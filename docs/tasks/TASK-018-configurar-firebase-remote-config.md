# TASK-018 — Configurar Firebase Remote Config

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado — Remote Config é um serviço Firebase que depende da inicialização básica)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar o `FeatureFlagService` sobre Firebase Remote Config, com valores padrão seguros e convenção de nomenclatura clara, para permitir que features futuras do VestiPro (especialmente as de evolução pós-MVP, EPIC-22 em diante) sejam ligadas/desligadas remotamente sem exigir novo deploy, e para permitir testes A/B ou rollout gradual quando necessário.

## Escopo técnico

- Criar em `lib/core/services/` a abstração `FeatureFlagService` com métodos como `isEnabled(String flagKey)`, `getString(String key)`, `getInt(String key)`, cada um com valor padrão explícito definido em código (nunca depender apenas do console remoto para o comportamento padrão do app).
- Configurar `firebase_remote_config` com `setConfigSettings` (intervalo mínimo de fetch adequado por ambiente — mais agressivo em dev, mais conservador em produção) e `setDefaults` com o mapa de valores padrão seguros.
- Definir convenção de nomenclatura de flags (ex.: `feature_<modulo>_<nome>_enabled`, `config_<modulo>_<parametro>`) documentada em `docs/architecture/feature-flags.md`, junto com uma tabela/registro de flags existentes contendo: nome da flag, descrição, responsável, data de criação, data de revisão prevista, valor padrão.
- Criar a primeira flag real de exemplo (ex.: `feature_insights_enabled` ou `feature_offline_sync_enabled`) para validar o fluxo ponta a ponta: definição no console/Emulator, leitura pelo `FeatureFlagService`, e uso condicional em um ponto do app (mesmo que seja um ponto simples, como esconder um item de menu no módulo de exemplo).
- Garantir que regras críticas (autorização, cálculo de preço, aprovações) nunca dependam exclusivamente de uma flag controlada só pelo cliente — Remote Config é para funcionalidade/experiência, não para segurança.
- Implementar rotina/processo documentado (não necessariamente automatizado nesta task) para remoção de flags temporárias após estabilização, evitando acúmulo de flags mortas no código ao longo do backlog de 206 tasks.

## Regras de negócio e restrições

- Toda flag deve ter um responsável e uma data de revisão registrados na tabela de flags — flag sem essas informações não deve ser mesclada.
- Valor padrão de cada flag deve ser seguro mesmo sem conexão com o Remote Config (ex.: uma feature nova deve ter padrão desligado até validação, uma configuração de limite deve ter um valor conservador padrão).
- Fetch de Remote Config nunca deve bloquear o carregamento inicial do app por tempo indefinido — usar timeout e fallback para os valores padrão locais.

## Testes obrigatórios

- Teste unitário do `FeatureFlagService` validando que, sem conexão com o Remote Config (fetch falha), o valor padrão local é retornado corretamente.
- Teste validando que a flag de exemplo (`feature_insights_enabled` ou equivalente) altera o comportamento do ponto de uso condicional criado nesta task.
- Teste garantindo que `setDefaults` é chamado no bootstrap antes de qualquer leitura de flag pelo restante do app.

## Critérios de aceite

- `FeatureFlagService` implementado sobre `firebase_remote_config`, com valores padrão seguros definidos em código.
- Convenção de nomenclatura e tabela de flags documentada em `docs/architecture/feature-flags.md`.
- Flag de exemplo funcional ponta a ponta (definição, leitura, uso condicional).
- Testes unitários passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
