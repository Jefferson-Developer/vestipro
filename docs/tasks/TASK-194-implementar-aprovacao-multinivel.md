# TASK-194 — Implementar aprovação multinível de pedidos/descontos

**Epic:** EPIC-29 — Pagamentos e Regras Comerciais Avançadas
**Status:** ⬜ Pendente
**Depende de:** TASK-103 (aprovação de pedidos, fluxo de aprovação de nível único a ser estendido), TASK-086 (políticas de desconto por perfil, base das faixas que determinam os níveis exigidos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Evoluir a aprovação de pedidos (TASK-103) e as políticas de desconto por perfil (TASK-086) para uma cadeia configurável de aprovadores por faixa de valor/percentual de desconto, registrando cada nível na trilha de auditoria e notificando o próximo aprovador automaticamente.

## Escopo técnico

- Modelar `ApprovalPolicy` por organização: faixas configuráveis (ex.: desconto até X% aprova gestor direto; acima disso, aprova diretoria), com lista ordenada de níveis/papéis aprovadores.
- Modelar `ApprovalChainInstance` vinculada ao pedido, com nível atual e histórico de decisões por nível (aprovado/rejeitado/comentário/autor/timestamp).
- Cloud Function `evaluateApprovalChain` decide, a cada submissão/decisão, qual o próximo nível necessário (server-side, reaproveitando o motor de precificação/políticas de desconto para saber o percentual real aplicado — nunca confiar em valor calculado no cliente).
- Ao avançar de nível, disparar notificação (central de notificações, TASK-151) para o próximo aprovador, com deep link direto para a tela de aprovação do pedido.
- Tela de aprovação (evolução de TASK-103) exibindo a cadeia completa: quem já aprovou, quem falta, motivo de cada faixa acionada.
- Rejeição em qualquer nível encerra a cadeia e retorna o pedido ao vendedor com o motivo registrado.

## Regras de negócio e restrições

- A faixa que determina os aprovadores necessários é sempre calculada a partir do resultado do motor de precificação (TASK-088) server-side, nunca do valor exibido no cliente.
- Aprovador de um nível não pode aprovar em nome de outro nível nem pular etapas da cadeia.
- Toda decisão (aprovação/rejeição) em qualquer nível é imutável no histórico (apenas acrescenta novo evento, nunca sobrescreve).
- Alteração na `ApprovalPolicy` da organização não pode alterar retroativamente cadeias já em andamento ou já concluídas.
- RBAC garante que somente o papel definido para aquele nível pode decidir naquele nível (validado em Cloud Function/Rules, não só ocultado na UI).

## Testes obrigatórios

- Testes da Cloud Function: determinação correta do próximo nível para diferentes faixas de desconto, rejeição em nível intermediário encerrando a cadeia, tentativa de aprovação fora de ordem (bloqueada).
- Testes de RBAC: usuário sem papel do nível atual não consegue decidir (negativo no Emulator Suite).
- Testes de notificação: próximo aprovador é notificado a cada avanço de nível.
- Testes de widget: visualização da cadeia completa, decisão de aprovar/rejeitar, estado de pedido rejeitado com motivo.

## Critérios de aceite

- Pedidos com desconto acima de cada faixa configurada exigem exatamente os níveis de aprovação definidos, em ordem.
- Toda decisão fica registrada de forma auditável e imutável.
- Próximo aprovador é notificado automaticamente a cada avanço.
- Nenhuma decisão de aprovação pode ser tomada por um perfil fora do nível correspondente.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
