# TASK-119 — Implementar projeção de fechamento

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ⬜ Pendente
**Depende de:** TASK-116 (dashboard de atingimento — a projeção usa o mesmo realizado/ritmo já calculado ali)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Estimar o resultado esperado ao final do período com base no ritmo atual de vendas, com metodologia de cálculo documentada explicitamente (nunca uma caixa preta), exibida junto ao dashboard de atingimento.

## Escopo técnico

- Definir e documentar (em `docs/` e/ou comentário de domínio) a metodologia de projeção: por exemplo, projeção linear simples = (realizado até a data) / (dias decorridos do período) × (dias totais do período); deixar espaço para métodos alternativos futuros (ex.: média móvel ponderada, sazonalidade) sem comprometer a implementação inicial.
- Criar `ClosingProjectionService` (domain) implementando o cálculo, recebendo o mesmo ViewModel de atingimento (TASK-116) como entrada, para garantir consistência de números entre as telas.
- Exibir a projeção junto ao dashboard de atingimento: valor projetado, comparação com a meta (projeção acima/abaixo da meta) e um texto curto explicando a metodologia usada (ex.: "com base no ritmo atual de vendas").
- Tratar casos-limite: período recém-iniciado (poucos dias decorridos — projeção pouco confiável, sinalizar isso visualmente/textualmente), período já encerrado (projeção = realizado final, sem necessidade de cálculo).
- Permitir que a metodologia seja substituída/estendida no futuro sem quebrar contrato (interface `ProjectionStrategy` com implementação linear como padrão).

## Regras de negócio e restrições

- A metodologia de cálculo deve estar documentada e acessível ao usuário — nunca uma "caixa preta" sem explicação, mesmo que resumida.
- A projeção nunca pode ser confundida visualmente com o valor realizado real — sempre rotulada explicitamente como estimativa/projeção.
- Em períodos com poucos dias decorridos (ex.: menos de 10% do período), a interface deve sinalizar que a projeção tem baixa confiabilidade.
- O cálculo deve usar a mesma base de "realizado" do dashboard de atingimento (TASK-116), para não gerar números divergentes.

## Testes obrigatórios

- Teste do `ClosingProjectionService` cobrindo: período no início (baixa confiabilidade sinalizada), meio do período, período já encerrado, meta zerada/inexistente.
- Teste garantindo que a projeção nunca diverge da base de realizado usada pelo dashboard de atingimento (mesmo input, resultado consistente).
- Teste de widget verificando que o rótulo "projeção"/"estimativa" está sempre visível e distinto do valor realizado.
- Teste do estado de baixa confiabilidade sendo exibido corretamente na UI.

## Critérios de aceite

- Projeção de fechamento calculada e exibida com metodologia documentada e explicável ao usuário.
- Projeção claramente distinta do valor realizado na interface.
- Casos-limite (início/fim de período) tratados corretamente.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
