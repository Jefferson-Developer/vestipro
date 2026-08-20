# TASK-216 — Implementar leitura de código de barras e QR para venda rápida

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Product), TASK-072 (variantes), TASK-097 (adição de produtos ao pedido), TASK-168 (importação de produtos com código de barras)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`

## Objetivo

Permitir busca e adição rápida de produtos/variantes por código de barras ou QR code em showroom,
feira, estoque ou visita, reduzindo digitação e erro de referência.

## Escopo técnico

- Criar abstração de scanner compatível com Android/iOS/Web quando possível, com fallback manual para
  plataformas/dispositivos sem câmera ou permissão.
- Indexar SKU, EAN, referência e códigos alternativos por variante, incluindo índice local offline.
- Permitir uso do scanner na busca global, detalhe do produto, pedido e conferência de mostruário.
- Definir formato seguro de QR interno quando necessário, sem incluir segredo, token longo ou dado
  pessoal sensível.
- Tratar permissões de câmera, erro de leitura, múltiplos resultados, código desconhecido e leitura
  repetida com feedback claro.

## Regras de negócio e restrições

- Scanner apenas identifica produto/variante; ele nunca contorna preço, estoque, crédito ou RBAC.
- QR interno não pode conceder acesso ou autorização por si só.
- Leitura repetida deve incrementar quantidade somente quando o contexto permitir e com feedback visível.
- Código desconhecido pode gerar sugestão de cadastro/correção apenas para perfil autorizado.

## Testes obrigatórios

- Teste de resolução de código para variante única, múltiplas variantes e código inexistente.
- Teste de índice local offline.
- Teste de widget para permissão negada, leitura válida, leitura inválida e fallback manual.
- Teste garantindo que adição via scanner passa pelo mesmo fluxo de preço/estoque do pedido normal.

## Critérios de aceite

- Vendedor consegue localizar/adicionar produto por código com velocidade e segurança.
- Funciona com fallback quando câmera não está disponível.
- Não há bypass de regras comerciais críticas.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
