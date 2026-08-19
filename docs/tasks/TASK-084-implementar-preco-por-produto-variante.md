# TASK-084 — Implementar preço por produto/variante

**Epic:** EPIC-11 — Tabelas de Preço e Condições Comerciais
**Status:** ⬜ Pendente
**Depende de:** TASK-083 (Price List, tabela à qual todo preço pertence), TASK-072 (geração de variantes produto-cor-tamanho, nível mais granular de preço)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir o cadastro de preços específicos por variante (produto + cor + tamanho) dentro de uma
Price List, quando o negócio precisar diferenciar preço por variante, com um fallback claro e
documentado para o preço definido no nível do produto quando não existir preço específico daquela
variante.

## Escopo técnico

- Modelar `PriceListItem` (`priceListId`, `productId`, `variantId` opcional, `price`,
  `updatedAt`) — quando `variantId` é nulo, o preço vale para todas as variantes do produto que não
  tenham item próprio.
- Implementar caso de uso `ResolvePriceForVariantUseCase`: busca preço específico da variante na(s)
  Price List(s) aplicável(is); se ausente, cai para o preço em nível de produto da mesma tabela; se
  também ausente, retorna um resultado explícito de "sem preço definido" (nunca um valor
  zero/nulo silencioso).
- Criar tela administrativa (Web/desktop) de cadastro em lote de preços por produto, com opção de
  "exceção por variante" para casos específicos (ex.: tamanho especial mais caro).
- Exibir na UI do produto (detalhe/grid) o preço resolvido pelo caso de uso acima, deixando claro
  ao vendedor quando um preço vem de uma exceção de variante (uso interno de auditoria/log, não
  necessariamente visível ao vendedor).
- Persistir `PriceListItem` na carga offline do catálogo (Drift), com sincronização incremental por
  tabela de preço.

## Regras de negócio e restrições

- Regra de fallback é única e documentada: variante específica → produto na mesma tabela → "sem
  preço definido"; nenhuma outra ordem de precedência é permitida sem alterar esta task.
- "Sem preço definido" para um produto em uma tabela aplicável deve impedir a adição desse
  produto/variante ao pedido usando aquela tabela, com mensagem clara ao vendedor.
- Cadastro em lote nunca pode sobrescrever silenciosamente um preço de variante já existente sem
  confirmação explícita do usuário administrativo.
- Cálculo de preço final (com desconto, campanha, condição) permanece de responsabilidade do motor
  de precificação (TASK-088) — este caso de uso resolve apenas o preço-base da tabela.

## Testes obrigatórios

- Testes do caso de uso `ResolvePriceForVariantUseCase`: preço específico de variante encontrado,
  fallback para preço de produto, nenhum preço encontrado, múltiplas Price Lists aplicáveis com
  prioridades diferentes.
- Testes de cadastro em lote: criação nova, atualização de preço existente, tentativa de
  sobrescrita sem confirmação, valores inválidos (negativo, não numérico).
- Testes de widget: tela de produto exibindo preço resolvido corretamente, estado "sem preço
  definido" bloqueando adição ao pedido.
- Testes de sincronização: preço atualizado no servidor reflete na carga offline local.

## Critérios de aceite

- Preço por variante e por produto coexistem na mesma tabela com o fallback documentado sempre
  respeitado.
- Produto/variante sem preço definido na tabela ativa nunca pode ser adicionado a um pedido usando
  aquela tabela.
- Cadastro em lote de preços funcional com proteção contra sobrescrita acidental.
- Preço exibido na UI é sempre o resultado do caso de uso de resolução, nunca um valor calculado
  diretamente na tela.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
