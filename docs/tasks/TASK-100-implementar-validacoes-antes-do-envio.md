# TASK-100 — Implementar validações antes do envio

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-099 — Implementar resumo comercial do pedido (validações consideram os valores já confirmados no resumo)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Impedir que pedidos inconsistentes sejam enviados: validar cliente ativo, preço vigente, quantidade disponível/coerente, condição de pagamento válida e permissões do vendedor antes de habilitar o envio do pedido.

## Escopo técnico

- Criar serviço de domínio `OrderSubmissionValidator` que verifica, antes de habilitar o envio: cliente ativo (não bloqueado/inativo), preço vigente (tabela de preço ainda válida na data), quantidade disponível/coerente com a disponibilidade retornada por TASK-090/TASK-091, condição de pagamento válida para o cliente/organização, e permissões do vendedor (RBAC) para o tipo de pedido/desconto solicitado.
- Exibir uma lista de pendências de validação de forma clara na UI antes do botão de envio (ex.: painel "Antes de enviar, resolva:"), cada item levando diretamente ao ponto do pedido que precisa de ajuste.
- Desabilitar o CTA de envio enquanto houver pendência bloqueante; diferenciar pendências bloqueantes de avisos não bloqueantes (ex.: aviso de desconto que irá para aprovação não bloqueia o envio, apenas informa).
- Reexecutar a validação sempre que um dado relevante do pedido mudar (item, cliente, condição de pagamento).

## Regras de negócio e restrições

- A validação client-side é apenas para UX — a mesma validação (ou equivalente) deve ser reexecutada server-side na submissão (TASK-101); nunca confiar somente no client.
- Cliente inativo, preço vencido ou condição de pagamento inválida bloqueiam o envio; falta de permissão do vendedor para o desconto solicitado não bloqueia sozinha (gera fluxo de aprovação, TASK-103), salvo se a política da organização exigir bloqueio total.
- Mensagens de erro nunca expõem detalhes técnicos — sempre orientadas à ação (ex.: "Este cliente está inativo. Reative-o para continuar").

## Testes obrigatórios

- Teste unitário do `OrderSubmissionValidator` cobrindo cada regra isoladamente e combinações de múltiplas pendências simultâneas.
- Teste de widget garantindo que o CTA de envio permanece desabilitado enquanto houver pendência bloqueante e habilita corretamente quando resolvidas.
- Teste cobrindo revalidação automática ao alterar item/cliente/condição de pagamento.
- Teste de RBAC negando envio de pedido com desconto fora do limite do perfil sem fluxo de aprovação configurado.

## Critérios de aceite

- Pedido inconsistente (cliente inativo, preço vencido, quantidade incoerente, condição de pagamento inválida, permissão insuficiente) nunca pode ser enviado sem resolução ou fluxo de aprovação correspondente.
- Vendedor recebe orientação clara e acionável sobre o que precisa corrigir.
- Validação client-side não substitui a validação server-side equivalente na submissão.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
