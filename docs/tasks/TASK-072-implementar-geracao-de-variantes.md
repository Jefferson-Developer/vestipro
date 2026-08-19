# TASK-072 — Implementar geração de variantes produto-cor-tamanho

**Epic:** EPIC-09 — Cores, Grades e Variantes
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product), TASK-070 (Implementar cadastro de cores) e TASK-071 (Implementar templates de grade) — a geração de variantes combina produto, cores associadas e template de grade, todos já modelados/implementados.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a geração automática de todas as combinações produto + cor + tamanho como variantes vendáveis, com cada variante tendo SKU e EAN próprios e independentes dos demais níveis (produto e cor).

## Escopo técnico

- Criar entidade `ProductVariant` (`productId`, `colorId`, `sizeId`, SKU próprio, EAN próprio, `organizationId`, status) representando cada combinação vendável.
- Criar `GenerateVariantsUseCase` que, dado um produto com N cores associadas e um template de grade associado, gera automaticamente todas as combinações cor × tamanho como variantes.
- Implementar geração automática de SKU derivado (ex.: SKU do produto + código da cor + código do tamanho), com possibilidade de edição manual por variante e validação de unicidade.
- Suportar regeneração incremental: adicionar uma nova cor ou tamanho a um produto já existente gera apenas as variantes faltantes, sem duplicar nem descartar variantes já referenciadas em pedidos.
- Implementar remoção/inativação de variante como soft delete (status inativo) — nunca exclusão física quando já referenciada por pedido.

## Regras de negócio e restrições

- Cada variante tem SKU e EAN próprios e independentes — produto, cor e variante podem ter EANs distintos simultaneamente.
- Não pode haver duas variantes ativas com o mesmo SKU ou o mesmo EAN dentro da mesma organização.
- A geração de variantes é idempotente: executá-la novamente para o mesmo produto não duplica combinações já existentes.
- Variante referenciada em pedido nunca é excluída fisicamente — apenas inativada, preservando o histórico.

## Testes obrigatórios

- Testes unitários do caso de uso de geração cobrindo: produto novo (gera tudo), produto existente com cor nova (gera apenas o incremento), produto existente sem alteração (idempotência).
- Testes de unicidade de SKU/EAN de variante dentro da organização (conflito deve falhar com `Failure` tipado).
- Teste cobrindo tentativa de exclusão física de variante referenciada em pedido (deve ser bloqueada/inativada).
- Teste de integração com Firebase Emulator validando a persistência das variantes geradas.

## Critérios de aceite

- Geração automática e incremental de variantes produto-cor-tamanho funcionando e idempotente.
- SKU/EAN por variante únicos, validados e editáveis manualmente quando necessário.
- Variante em uso nunca é excluída fisicamente, apenas inativada.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
