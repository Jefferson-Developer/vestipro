# TASK-078 — Implementar detalhe visual de produto

**Epic:** EPIC-10 — Catálogo Premium
**Status:** ⬜ Pendente
**Depende de:** TASK-072 (variantes produto-cor-tamanho, base da galeria e da grade), TASK-074 (disponibilidade por variante, exibida na grade de tamanhos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela de detalhe do produto como a experiência completa de compra B2B do VestiPro:
galeria com zoom, seleção de cor que atualiza a galeria e a disponibilidade, grade de tamanhos com
estoque por variante, preço da tabela vigente e um caminho direto e sempre acessível para adicionar
o produto ao pedido em andamento.

## Escopo técnico

- Criar `ProductDetailBloc` que carrega produto, variantes, preço (tabela ativa) e disponibilidade
  em paralelo, compondo um estado único e consistente para a tela.
- Implementar galeria com `photo_view` (zoom, arrastar, indicador de posição), sincronizada com a
  cor selecionada — trocar de cor atualiza as imagens e a disponibilidade sem recarregar a tela
  inteira.
- Reutilizar o componente de swatch de cor e a grade de tamanhos do Design System
  (`design_system/components/catalog/`), exibindo disponibilidade por variante (pronta entrega,
  futuro, indisponível) sem poluir a grade.
- Implementar CTA fixo "Adicionar ao pedido" (sticky no mobile, sempre visível no scroll) que
  dispara o caso de uso de adição de item ao rascunho de pedido (integração com EPIC-13, quando
  disponível) sem duplicar a lógica de cálculo do motor de precificação.
- Exibir preço por variante com fallback para preço de produto (ver TASK-084) de forma transparente
  ao usuário.
- Registrar eventos `product_viewed` (com origem: grid, busca, favoritos, compartilhamento) e
  `product_added_to_order`.

## Regras de negócio e restrições

- Preço, desconto e disponibilidade exibidos são somente leitura do resultado do domínio/backend —
  a tela nunca calcula preço ou aplica regra de desconto por conta própria.
- Trocar de cor não pode deixar a tela em estado inconsistente (ex.: tamanho selecionado que não
  existe para a nova cor deve ser tratado explicitamente).
- Grade de tamanhos deve preservar quantidades digitadas mesmo se a conexão cair durante a
  digitação.
- Produto sem imagem, sem variante disponível ou sem preço na tabela ativa deve ter tratamento
  visual explícito (nunca tela quebrada ou campo vazio silencioso).

## Testes obrigatórios

- Testes de bloc: carregamento completo, falha parcial (preço indisponível, estoque indisponível),
  troca de cor, produto sem variantes, offline com cache local.
- Testes de widget/golden: galeria com zoom, grade de tamanhos com estoque parcial, CTA fixo em
  mobile e em desktop, estado sem imagem, título longo, texto ampliado (acessibilidade).
- Teste de integração cobrindo o fluxo "abrir produto → trocar cor → preencher grade → adicionar ao
  pedido".
- Teste garantindo que o preço exibido nunca diverge do valor retornado pelo motor de precificação
  para o mesmo cenário.

## Critérios de aceite

- Troca de cor atualiza galeria, grade de tamanhos e disponibilidade de forma consistente e sem
  travar a tela.
- CTA "Adicionar ao pedido" permanece acessível durante toda a rolagem da tela, em qualquer
  breakpoint.
- Estoque por variante exibido de forma clara (pronta entrega/futuro/indisponível) sem urgência
  falsa.
- Preço exibido idêntico ao retornado pela camada de domínio/motor de precificação.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
