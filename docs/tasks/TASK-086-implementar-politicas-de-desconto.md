# TASK-086 — Implementar políticas de desconto por perfil

**Epic:** EPIC-11 — Tabelas de Preço e Condições Comerciais
**Status:** ⬜ Pendente
**Depende de:** TASK-029 (RBAC, base dos perfis aos quais a política de desconto se aplica), TASK-083 (Price List, escopo ao qual a política pode estar associada)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Definir e aplicar limites de desconto configuráveis por perfil (`SALES_REP`, `SALES_ASSISTANT`,
`SALES_MANAGER`, etc.), de modo que descontos acima do limite do perfil do vendedor gerem bloqueio
ou disparem um fluxo de aprovação — preparando o contrato de dados que as tasks TASK-103 (aprovação
de pedidos) e TASK-194 (aprovação multinível) vão consumir.

## Escopo técnico

- Modelar `DiscountPolicy` (`id`, `organizationId`, `companyId`, `role`, `maxDiscountPercent`,
  `priceListIds` opcionais, `requiresApprovalAbovePercent` quando diferente do limite máximo,
  `status`) no domínio.
- Implementar caso de uso `ValidateDiscountUseCase`: recebe perfil do usuário, desconto solicitado e
  tabela de preço, retorna um resultado tipado (`Allowed`, `RequiresApproval`, `Blocked`) — nunca um
  booleano simples, para já expor o suficiente à UI e ao fluxo de aprovação.
- Definir e documentar o contrato de saída consumido por TASK-103/TASK-194 (ex.:
  `DiscountApprovalRequest` com solicitante, perfil, desconto solicitado, limite do perfil, pedido
  associado) mesmo que a tela de aprovação ainda não exista.
- Criar tela administrativa de cadastro de política de desconto por perfil (Web/desktop),
  restrita a `OWNER`/`ADMIN`/`FINANCE`.
- Validar desconto tanto na UI do pedido (bloqueio/aviso imediato) quanto — de forma definitiva e
  obrigatória — na Cloud Function de submissão de pedido (TASK-101) e no motor de precificação
  (TASK-088); a validação client-side é só feedback de UX.
- Registrar auditoria administrativa para criação/edição de política de desconto.

## Regras de negócio e restrições

- Desconto acima do limite do perfil nunca pode ser aplicado silenciosamente — o pedido é bloqueado
  ou marcado como pendente de aprovação, nunca enviado como se estivesse aprovado.
- A validação de desconto no cliente é apenas uma conveniência de UX; a fonte de verdade e o
  bloqueio real ocorrem sempre em Cloud Function/domínio server-side.
- Política de desconto pode ser restrita a tabelas de preço específicas; na ausência de restrição,
  vale para todas as tabelas da empresa.
- Perfis administrativos (`OWNER`, `ADMIN`) podem ter política sem limite (`maxDiscountPercent`
  igual a 100), mas isso deve ser uma configuração explícita, nunca um comportamento implícito do
  perfil.

## Testes obrigatórios

- Testes do caso de uso `ValidateDiscountUseCase`: desconto dentro do limite (`Allowed`), desconto
  entre o limite e o teto que exige aprovação (`RequiresApproval`), desconto acima do teto máximo
  (`Blocked`), perfil sem política cadastrada (comportamento padrão explícito e testado).
- Testes de domínio: política sem `maxDiscountPercent` definido, política associada a Price List
  inexistente, edição de política reduzindo limite com pedidos já em aprovação.
- Testes de widget: bloqueio visual ao digitar desconto acima do permitido, aviso de "necessita
  aprovação" no resumo do pedido.
- Teste de segurança confirmando que a Cloud Function de submissão de pedido rejeita/enfileira para
  aprovação um desconto acima do limite mesmo se a UI enviar o pedido como se estivesse aprovado.

## Critérios de aceite

- Cada perfil possui um limite de desconto configurável, com efeito real sobre o pedido.
- Desconto acima do limite nunca é aplicado sem bloqueio ou aprovação, mesmo manipulando a
  requisição fora da UI.
- Contrato de dados para aprovação está documentado e pronto para ser consumido por TASK-103/
  TASK-194 sem necessidade de retrabalho de modelo.
- Toda criação/edição de política de desconto gera registro de auditoria.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
