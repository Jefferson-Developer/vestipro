# TASK-207 — Modelar kits, pacotes e sortimentos

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Product), TASK-072 (variantes produto-cor-tamanho), TASK-083 (Price List), TASK-090 (saldo por variante)

## Agentes obrigatórios

- `flutter-senior-architect`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Modelar kits, pacotes e sortimentos vendáveis para moda B2B, permitindo que a marca configure conjuntos
por grade, perfil de cliente, coleção ou campanha. Essa base sustenta venda por pack, sortimento ideal,
pré-venda, redução de erro no pedido e maior ticket médio.

## Escopo técnico

- Criar entidades de domínio para `CommercialPack`, `PackComponent` e `AssortmentRule`, suportando:
  composição fixa, composição flexível, proporção por cor/tamanho, quantidade mínima/máxima, vigência,
  coleção/campanha, segmento de cliente, canal e status.
- Permitir componentes por variante específica, produto inteiro, cor, tamanho, categoria ou coleção,
  sempre resolvidos para variantes vendáveis antes do cálculo comercial.
- Modelar política de preço do pacote: soma dos componentes, preço fechado, desconto de pacote ou item
  bonificado, apenas como contrato para o motor de precificação aplicar depois.
- Modelar política de estoque: consumo direto do saldo das variantes componentes ou estoque separado
  para pacote pré-montado, com comportamento explícito e auditável.
- Criar DTOs/mappers/tabelas locais/collections necessárias seguindo o padrão offline-first,
  multi-tenant e auditável.

## Regras de negócio e restrições

- Pacote não pode referenciar variante inativa, produto excluído ou coleção fora do escopo da organização.
- Não permitir composição circular: um pacote não pode conter outro pacote que contenha o primeiro direta
  ou indiretamente.
- A modelagem não calcula preço final nem reserva estoque; ela apenas define a estrutura que será
  consumida pelo motor de precificação e pelo fluxo de pedido.
- Alteração em pacote ativo deve versionar a configuração para preservar histórico de pedidos antigos.
- Configuração e publicação de pacote exigem RBAC administrativo/comercial; vendedor apenas consome.

## Testes obrigatórios

- Teste unitário dos validadores de composição: componente inválido, proporção inválida, quantidade zero,
  circularidade e vigência expirada.
- Teste de mapper DTO ↔ Entity cobrindo composição fixa, flexível e por grade.
- Teste de isolamento multi-tenant no repositório/datasource.
- Teste de versionamento garantindo que alteração em pacote ativo cria nova versão sem reescrever pedidos.

## Critérios de aceite

- Kits, pacotes e sortimentos podem ser modelados de forma flexível, versionada e auditável.
- O modelo diferencia claramente preço, estoque e composição, sem misturar regra de cálculo na entidade.
- A estrutura fica pronta para venda por pacote no pedido sem remodelagem posterior.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da
  execução.

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente de representante: `.claude/agents/vestipro-sales-representative-specialist.md`
- Agente de operações comerciais: `.claude/agents/vestipro-commercial-ops-strategist.md`
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
