# TASK-203 — Implementar portal administrativo avançado

**Epic:** EPIC-31 — Administração Avançada e Data Platform
**Status:** ⬜ Pendente
**Depende de:** TASK-042 (lista de usuários da organização, referência de gestão de acesso a ser estendida), TASK-033 (auditoria administrativa, destino obrigatório de toda ação do portal)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Criar um portal administrativo para a própria equipe VestiPro (suporte/operação da plataforma, não do cliente final) com visão multi-organização, ferramentas de diagnóstico e suporte, sempre respeitando escopo de acesso auditado — nunca um acesso irrestrito e não rastreado aos dados dos clientes da plataforma.

## Escopo técnico

- Novo nível de acesso "Operador VestiPro" (papel interno, fora da hierarquia RBAC normal de uma organização), com autenticação e RBAC próprios, distintos dos perfis de organização (`OWNER`, `ADMIN`, etc.).
- Tela multi-organização: busca de organização, visão consolidada de saúde (uso, erros de sincronização, volume de pedidos, tickets abertos), sem expor dados comerciais/pessoais de clientes finais além do estritamente necessário para suporte.
- Ferramentas de diagnóstico: consulta de status de sincronização de um usuário/dispositivo, consulta de logs técnicos (sem dados sensíveis), reprocessamento assistido de falhas conhecidas (ex.: reprocessar item da Outbox travado) — sempre com ação registrada.
- Toda ação do operador sobre dados de uma organização é obrigatoriamente registrada no audit log central (TASK-033), incluindo qual organização, qual dado foi acessado/alterado e o motivo informado.
- Solicitação de acesso a dados sensíveis de uma organização específica exige justificativa registrada (ex.: número de ticket de suporte) antes de liberar a visão detalhada.

## Regras de negócio e restrições

- Nenhum operador VestiPro acessa dados de uma organização sem que essa ação fique registrada no audit log, com motivo.
- Acesso a dados sensíveis (financeiros, pessoais) exige justificativa explícita; acesso "de passagem" sem motivo não é permitido para esses dados.
- Portal administrativo é isolado do app comercial do cliente final (rota, autenticação e ambiente próprios), evitando qualquer confusão entre "admin da organização" (perfil `ADMIN` do cliente) e "operador VestiPro".
- Toda ação de suporte que altera dado de uma organização segue o mesmo rigor de auditoria de qualquer alteração administrativa sensível do sistema.

## Testes obrigatórios

- Testes de RBAC: operador VestiPro não pode agir fora do escopo permitido; usuário comum de organização não acessa o portal administrativo.
- Testes de auditoria: toda consulta/ação sensível gera entrada completa no audit log (quem, quando, qual organização, motivo).
- Testes de isolamento: consulta multi-organização nunca mistura dados de organizações diferentes na mesma tela sem intenção explícita.
- Testes de widget: busca de organização, diagnóstico de sincronização, fluxo de justificativa obrigatória para dado sensível.

## Critérios de aceite

- Apenas operadores VestiPro autenticados no portal próprio acessam a visão multi-organização.
- Toda ação sensível sobre dados de uma organização fica registrada no audit log com motivo.
- Nenhum dado comercial/pessoal de cliente final é exposto sem justificativa registrada quando classificado como sensível.
- Portal administrativo é claramente segregado do app comercial usado pelas organizações clientes.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
