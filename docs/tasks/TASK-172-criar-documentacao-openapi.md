# TASK-172 — Criar documentação OpenAPI

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Status:** ⬜ Pendente
**Depende de:** TASK-171 (API pública — esta task documenta a API já implementada).

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Produzir uma especificação OpenAPI completa da API pública do VestiPro, com exemplos reais de request/response, e publicar um portal de documentação navegável para parceiros técnicos.

## Escopo técnico

- Escrever especificação OpenAPI 3.x cobrindo todos os endpoints de TASK-171: parâmetros, schemas de request/response, códigos de erro, autenticação (API key/OAuth), rate limiting documentado.
- Incluir exemplos reais (não genéricos) de payload para os recursos principais: cliente, produto/variante, pedido, estoque — refletindo campos e formatos efetivamente usados pelo VestiPro (moeda, datas, enums de status).
- Publicar portal de documentação (ex.: Redoc/Swagger UI hospedado via Firebase Hosting) acessível a parceiros autenticados ou via link controlado, conforme política de exposição definida pela organização/produto.
- Manter a especificação como artefato versionado no repositório, gerado/validado automaticamente (lint de OpenAPI) para não divergir do código real dos endpoints.
- Documentar explicitamente os erros comuns (401, 403, 404, 429) com formato de corpo de erro padronizado.

## Regras de negócio e restrições

- Documentação nunca expõe exemplos com dados reais de clientes/organizações — apenas dados fictícios plausíveis.
- Especificação deve refletir fielmente o comportamento real da API; divergência entre doc e comportamento é tratada como bug de documentação a corrigir.
- Portal de documentação não pode expor endpoints/rotas internas que não fazem parte da API pública oficial.

## Testes obrigatórios

- Validação automática (lint) do arquivo OpenAPI (schema válido, sem endpoints órfãos).
- Roteiro de conferência: cada endpoint documentado corresponde a um endpoint real testado em TASK-171.
- Teste de acesso ao portal de documentação (publicado corretamente, sem expor rota interna).

## Critérios de aceite

- Especificação OpenAPI cobre 100% dos endpoints públicos com exemplos reais de request/response.
- Portal de documentação publicado e navegável por um parceiro externo.
- Nenhuma divergência conhecida entre a especificação e o comportamento real da API.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
