# TASK-163 — Criar testes offline e de sincronização

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Status:** ⬜ Pendente
**Depende de:** TASK-109 (motor de sincronização incremental, alvo principal destes testes),
TASK-110 (resolução de conflitos, cujos três modos precisam ser validados)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Validar, com testes automatizados, os cenários reais de operação sem internet — criação, edição,
conflito e reconexão — incluindo retry e backoff, como terceiro pilar do checklist de qualidade que
antecede o release do MVP (TASK-166). O offline-first é um dos pilares diferenciais do VestiPro e
deve ser tratado com o mesmo rigor de uma carteira financeira.

## Escopo técnico

- Criar suíte de testes simulando cenários reais sem internet: criação de pedido/atividade CRM
  offline, edição offline, fechamento e reabertura do app com Outbox pendente.
- Testar o motor de sincronização incremental (TASK-109) reconectando após período offline: itens da
  Outbox migram `pending → syncing → synced`, sem duplicação e sem perda.
- Testar a resolução de conflito (TASK-110) nos três modos definidos: last-write-wins seguro, merge
  por campo, bloqueio + resolução manual para pedidos e dados financeiros.
- Simular falhas de rede intermitentes (timeouts, quedas no meio da sincronização) validando retry
  com backoff exponencial e que a Outbox nunca fica em estado inconsistente.
- Usar fakes/mocks de conectividade (`connectivity_plus`) e de datasource remoto controláveis para
  simular latência, erro e sucesso de forma determinística.

## Regras de negócio e restrições

- Nenhum teste pode aceitar perda de dado do usuário como resultado válido de um cenário de falha;
  toda falha deve ser recuperável.
- Estado `conflict` na Outbox é testado explicitamente para pedidos (bloqueio + resolução manual),
  nunca resolvido silenciosamente como last-write-wins.
- Reconexão após o app ser fechado/reaberto retoma a sincronização a partir do estado persistido, sem
  depender de estado em memória perdido.

## Testes obrigatórios

- Teste: criação de pedido offline sobrevive ao fechamento do app e sincroniza corretamente ao
  reconectar.
- Teste: falha de rede no meio da sincronização aciona retry com backoff exponencial, sem duplicar o
  item na Outbox.
- Teste: conflito de pedido é sinalizado como `conflict` e exige resolução manual, nunca sobrescrito
  automaticamente.
- Teste: duas sessões editando a mesma entidade não sensível resolvem via merge/last-write-wins
  conforme a política definida por entidade.
- Teste: sincronização incremental por cursor não reprocessa itens já sincronizados após múltiplas
  reconexões.

## Critérios de aceite

- Todos os cenários offline críticos (criação, edição, conflito, reconexão) têm teste automatizado
  passando.
- Nenhum cenário testado resulta em perda silenciosa de dado do usuário.
- Retry/backoff exponencial comprovadamente evita duplicação e não trava a Outbox em estado
  inconsistente.
- Conflitos de pedidos/dados financeiros sempre exigem resolução manual nos testes, nunca resolução
  automática.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
