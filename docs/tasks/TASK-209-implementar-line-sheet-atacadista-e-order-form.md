# TASK-209 — Implementar line sheet atacadista e order form por coleção

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-076 (home do catálogo), TASK-080 (lookbook e campanhas), TASK-081 (compartilhamento de catálogo), TASK-095 (Order/OrderItem), TASK-098 (tela de grade no pedido)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Criar line sheets digitais e order forms atacadistas por coleção/campanha, combinando apresentação
visual de moda com entrada rápida de pedido por estilo, cor e grade. Isso substitui PDF + planilha e
torna o catálogo diretamente vendável.

## Escopo técnico

- Modelar `LineSheet` com coleção/campanha, ordenação editorial, produtos destacados, regras de acesso,
  preço visível por perfil e estado de publicação.
- Criar visualização de line sheet em mobile/tablet/Web com fotos, referência, cores, preço, estoque
  resumido, tags e entrada rápida por grade.
- Criar modo `OrderForm` denso para compradores e vendedores adicionarem quantidades em matriz por
  produto/cor/tamanho, com totais por linha, produto e coleção.
- Permitir compartilhamento controlado do line sheet, reaproveitando as regras de link seguro da TASK-081
  e registrando analytics de abertura, filtro, produto visualizado e item adicionado.
- Suportar exportação/visualização imprimível simples quando aplicável, sem substituir a exportação PDF
  avançada da TASK-148.

## Regras de negócio e restrições

- Link compartilhado só mostra produtos, preços e estoque permitidos para aquele cliente/perfil.
- Preço e estoque exibidos podem ter indicação de atualização, mas a submissão do pedido sempre revalida
  tudo no servidor.
- Line sheet publicado deve preservar versão; alterações editoriais relevantes criam nova versão.
- Order form não pode inserir quantidade em variante indisponível sem regra explícita de backorder ou
  pré-venda.

## Testes obrigatórios

- Teste de permissões do line sheet compartilhado por cliente/perfil.
- Teste de widget do order form em mobile, tablet e Web, incluindo grade extensa sem overflow.
- Teste de analytics: abertura, filtro, produto visualizado e item adicionado.
- Teste de versionamento: pedido registra a versão do line sheet/order form usado.

## Critérios de aceite

- Usuário consegue vender uma coleção inteira por line sheet/order form sem sair para planilhas.
- Line sheet respeita RBAC, tabela de preço, visibilidade de estoque e versão publicada.
- Interações geram dados suficientes para medir interesse de coleção e conversão.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
