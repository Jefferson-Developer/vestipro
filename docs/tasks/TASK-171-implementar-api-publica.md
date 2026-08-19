# TASK-171 — Implementar API pública (REST)

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Status:** ⬜ Pendente
**Depende de:** TASK-015 (Cloud Functions), TASK-169 (framework de integração ERP — API pública reaproveita a camada de mapeamento/autorização já criada).

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Expor endpoints REST autenticados para que parceiros e sistemas externos consultem/integrem dados do VestiPro (clientes, produtos, pedidos, estoque) sem passar pelo app, com autenticação por API key ou OAuth, rate limiting e escopo de dados restrito à organização do token.

## Escopo técnico

- Definir endpoints REST versionados (ex.: `/v1/customers`, `/v1/products`, `/v1/orders`) implementados como Cloud Functions HTTPS, cobrindo leitura e, quando aplicável, criação de pedido.
- Implementar autenticação por API key (par chave/segredo por organização) e, opcionalmente, fluxo OAuth 2.0 client credentials para parceiros que exigem token de curta duração.
- Middleware de autorização garantindo que toda consulta é automaticamente restrita ao `organizationId` do token — nunca aceitar `organizationId` vindo do corpo/query da requisição como fonte de verdade.
- Rate limiting por chave/organização (ex.: N requisições por minuto), com resposta HTTP 429 padronizada e headers de limite restante.
- Paginação por cursor em todos os endpoints de listagem (nunca offset simples em coleções grandes).
- Log de uso da API por chave (endpoint, timestamp, status, latência) para suporte e faturamento futuro.
- Painel/tela para o gestor gerar, revogar e rotacionar API keys da própria organização.

## Regras de negócio e restrições

- Toda autorização é resolvida no backend a partir do token — nunca confiar em parâmetro de organização enviado pelo cliente.
- API key revogada invalida requisições imediatamente (sem cache de autorização desatualizado além de um TTL curto e documentado).
- Rate limit é sempre por organização/chave, nunca compartilhado globalmente entre organizações diferentes.
- Endpoints de escrita (ex.: criar pedido) respeitam as mesmas regras de negócio e validações do app (motor de precificação, disponibilidade de estoque) — a API não é um atalho que ignora regra de domínio.

## Testes obrigatórios

- Teste de autenticação: chave válida, chave inválida, chave revogada, tentativa de escopo cruzado entre organizações (deve falhar).
- Teste de rate limiting (excedendo o limite configurado).
- Teste de paginação por cursor com grandes volumes.
- Teste de criação de pedido via API respeitando as mesmas regras de domínio do app (preço, estoque).
- Teste de log de uso por chave.

## Critérios de aceite

- Parceiro externo consulta/cria dados usando apenas API key, restrito à própria organização.
- Nenhuma requisição lê/escreve dados de outra organização, mesmo manipulando parâmetros.
- Rate limiting funciona e é reportado de forma padronizada ao consumidor.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
