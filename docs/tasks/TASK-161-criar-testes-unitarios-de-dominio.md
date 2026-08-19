# TASK-161 — Criar testes unitários da camada de domínio

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Status:** ⬜ Pendente
**Depende de:** TASK-004 (arquitetura feature-first + Clean Architecture, que define a camada de
domínio a testar), TASK-009 (estrutura inicial de testes)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Garantir cobertura de teste automatizado para os casos de uso e serviços de domínio críticos
acumulados ao longo de todo o backlog — motor de precificação, RBAC, submissão de pedido, resolução
de conflito de sincronização, engine de insights e cálculo de metas — como primeiro pilar do
checklist de release do MVP (TASK-166).

## Escopo técnico

- Auditar a camada `domain/` de todas as features já implementadas até este ponto do backlog e
  identificar lacunas de cobertura antes de escrever qualquer teste novo.
- Criar/completar testes unitários (`flutter_test`, `test`, `mocktail`, `bloc_test` onde aplicável)
  para os casos de uso e serviços de domínio críticos identificados, cobrindo sucesso, falhas
  previsíveis, valores limite, campos nulos e listas vazias.
- Medir a cobertura atual (`flutter test --coverage`) antes de iniciar e novamente ao final, como
  evidência objetiva de progresso.
- Priorizar os fluxos obrigatórios listados em `tasks.md` (seção 15): login, criação de organização,
  cadastro de cliente, cadastro de produto com cores/grades, criação de pedido offline, sincronização
  com conflito, aprovação de desconto, geração de insight, exportação de relatório, RBAC negando ação
  não autorizada.

## Regras de negócio e restrições

- Nenhuma regra de negócio crítica (precificação, RBAC, número de pedido, aprovação) pode permanecer
  sem teste automatizado ao final desta task.
- Testes de domínio não podem depender de Flutter/Firebase/Drift reais (mock de contratos de
  repositório) — o domínio deve ser testável em isolamento puro Dart.
- Não reescrever regra de negócio existente apenas para "facilitar o teste" sem justificativa técnica
  registrada.

## Testes obrigatórios

- Testes cobrindo o motor de precificação: desconto dentro/fora do limite do perfil, bloqueio/fluxo
  de aprovação, campanha promocional aplicada corretamente.
- Testes cobrindo RBAC: perfil autorizado permite a ação, perfil não autorizado bloqueia com
  `PermissionFailure`.
- Testes cobrindo submissão de pedido: grade completa, item inválido, cliente/tabela de preço
  ausente, conflito de estoque.
- Testes cobrindo resolução de conflito de sincronização: last-write-wins seguro, merge por campo,
  bloqueio para dados financeiros.
- Relatório de cobertura (`flutter test --coverage`) comparando o estado antes/depois desta task.

## Critérios de aceite

- Cobertura da camada de domínio/casos de uso atinge a meta definida pelo agente sênior (referência:
  domínio 90%, casos de uso 90%, mappers 100%), com relatório de cobertura como evidência.
- Todos os fluxos críticos listados na especificação possuem teste automatizado correspondente.
- `flutter test` roda 100% verde localmente; a lista de gaps de cobertura anterior é documentada como
  resolvida ou como pendência explicitamente justificada.
- Nenhum teste depende de infraestrutura real (Firebase/Drift) para validar regra de domínio pura.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
