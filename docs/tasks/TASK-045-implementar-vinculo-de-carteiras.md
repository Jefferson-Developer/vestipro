# TASK-045 — Implementar vínculo de vendedores a carteiras

**Epic:** EPIC-05 — Usuários e Equipes
**Status:** ⬜ Pendente
**Depende de:** TASK-044 (equipes comerciais — o vínculo de carteira é definido no contexto de vendedores e gestores já organizados em Teams)

> **Nota:** o contrato de visibilidade definido nesta task será consumido futuramente pela TASK-051 (implementação da carteira de clientes). Não modelar aqui a entidade `Customer` em si — apenas o vínculo de responsabilidade e a regra de visibilidade.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Definir e implementar o vínculo entre vendedores e sua carteira de clientes, e a regra de visibilidade em cascata por role (vendedor só vê seus clientes; gestor vê os da sua equipe; admin vê todos), preparando o contrato que a TASK-051 irá consumir.

## Escopo técnico

- Modelar o vínculo de responsabilidade (ex.: `PortfolioAssignment`), contendo `userId`, `teamId`, escopo de atribuição (cliente individual ou critério, como região/segmento) e `organizationId`/`companyId`.
- Criar `AssignPortfolioPage` permitindo que `SALES_MANAGER`/`ADMIN`/`OWNER` vinculem vendedores a clientes ou a critérios de carteira; a entidade `Customer` em si é escopo de TASK-048/TASK-051 — aqui trata-se apenas do vínculo de responsabilidade.
- Criar um serviço de domínio (ex.: `PortfolioVisibilityService`) que resolve, para um usuário autenticado, quais clientes ele pode visualizar: `SALES_REP` vê apenas os seus; `SALES_MANAGER` vê os de toda(s) a(s) sua(s) Team(s); `ADMIN`/`OWNER` veem toda a organização.
- Documentar explicitamente, na implementação, o contrato (interface/caso de uso) que a TASK-051 deverá consumir para filtrar a listagem de carteira de clientes.
- Aplicar a regra de visibilidade tanto nas queries do client quanto na validação do backend (Firestore Security Rules/Cloud Function) — nunca apenas como filtro de UI.

## Regras de negócio e restrições

- Reatribuição de carteira (troca do vendedor responsável) deve preservar integralmente o histórico do cliente — nunca apagar interações ou pedidos anteriores.
- Um cliente possui um vendedor responsável principal; se carteira compartilhada entre múltiplos vendedores for necessária, essa regra deve ser explicitamente decidida e documentada nesta task, nunca implícita no código.
- Todo vínculo é sempre escopado à organização/empresa ativa; nunca vazamento de vínculos entre tenants.

## Testes obrigatórios

- Testes de domínio/caso de uso cobrindo a resolução de visibilidade para cada role (`SALES_REP`, `SALES_MANAGER`, `ADMIN`/`OWNER`).
- Testes de Firestore Security Rules (Emulator Suite) garantindo que um `SALES_REP` não consegue ler documentos de clientes fora de sua carteira, mesmo manipulando a query no client.
- Teste de reatribuição de carteira comprovando que o histórico do cliente é preservado integralmente.

## Critérios de aceite

- Regras de visibilidade por role implementadas e validadas no backend, não apenas na interface.
- Contrato de consumo pela TASK-051 documentado de forma explícita na entrega.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
