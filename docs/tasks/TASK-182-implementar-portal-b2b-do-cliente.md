# TASK-182 — Implementar portal B2B self-service do cliente

**Epic:** EPIC-25 — Catálogo Avançado e Portal B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-179 (catálogo white-label), TASK-101 (submissão do pedido — o portal reaproveita o catálogo com marca própria e o fluxo de pedido já existente).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Criar um portal onde o próprio cliente final (comprador da loja/varejo) acessa com login próprio para consultar o catálogo, acompanhar seus pedidos e repetir compras anteriores — sem depender do vendedor para cada interação —, com um papel de RBAC específico de "cliente externo" que nunca acessa dados de outros clientes.

## Escopo técnico

- Criar um novo tipo de identidade/papel no RBAC existente: "cliente externo" (customer portal user), vinculado a um `customerId` específico dentro de uma organização, distinto dos papéis internos (vendedor, gestor, admin) já modelados.
- Implementar autenticação própria para esse papel (Firebase Authentication, fluxo separado do login interno da força de vendas), com provisionamento do acesso feito pelo vendedor/gestor (convite) — cliente não se autocadastra livremente na organização.
- Portal exibe: catálogo com tema white-label da organização (TASK-179), histórico de pedidos do próprio cliente, status/rastreio de pedidos em andamento e ação de "repetir pedido" (recriar um carrinho a partir de um pedido anterior).
- Repetir pedido deve revalidar preço e disponibilidade atuais no momento da ação — nunca reaproveitar preço/estoque desatualizado do pedido antigo.
- Submissão de novo pedido pelo próprio cliente externo segue as mesmas regras de negócio do fluxo de submissão existente (TASK-101): motor de precificação, disponibilidade, fluxo de aprovação quando aplicável.
- Regras de segurança (Firestore Rules) específicas garantindo que o papel "cliente externo" só lê/escreve dados do próprio `customerId`, nunca de outro cliente da mesma organização nem de outra organização.

## Regras de negócio e restrições

- Cliente externo nunca acessa pedidos, dados de contato ou histórico de outro cliente, mesmo dentro da mesma organização — isolamento por `customerId`, não apenas por `organizationId`.
- Provisionamento do acesso do cliente externo é sempre iniciado por um usuário interno (vendedor/gestor) da organização — o portal não permite autocadastro livre de qualquer pessoa como cliente de uma organização.
- "Repetir pedido" nunca reaproveita preço ou estoque desatualizado — sempre revalida contra o estado atual da tabela de preço e disponibilidade.
- Pedido criado pelo cliente externo segue o mesmo pipeline de regras de negócio; quando a política comercial da organização exigir aprovação do vendedor/gestor para pedidos de portal, o gatilho básico de "pedido pendente de aprovação" deve existir aqui, já que o portal só faz sentido publicado com essa salvaguarda mínima (a aprovação multinível completa pertence a EPIC-29).

## Testes obrigatórios

- Teste de RBAC/Firestore Rules: cliente externo lê/escreve exclusivamente dados do próprio `customerId`; tentativa de acessar outro `customerId` ou outra organização falha.
- Teste de provisionamento de acesso (convite feito pelo vendedor, cliente completa cadastro/login).
- Teste de "repetir pedido" revalidando preço e disponibilidade atuais (cenário de preço/estoque alterado desde o pedido original).
- Teste de submissão de pedido pelo cliente externo passando pelas mesmas regras de negócio do fluxo interno.
- Teste de widget do portal (catálogo com tema, histórico de pedidos, ação de repetir pedido) em mobile/tablet/Web.

## Critérios de aceite

- Cliente final acessa o portal com login próprio, vê catálogo com a marca da organização e seu próprio histórico de pedidos.
- Nenhum cliente externo consegue acessar dados de outro cliente, em nenhuma circunstância.
- "Repetir pedido" sempre reflete preço e disponibilidade atuais, nunca dados obsoletos.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
