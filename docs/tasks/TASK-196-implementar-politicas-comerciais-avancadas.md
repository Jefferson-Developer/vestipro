# TASK-196 — Implementar políticas comerciais avançadas

**Epic:** EPIC-29 — Pagamentos e Regras Comerciais Avançadas
**Status:** ⬜ Pendente
**Depende de:** TASK-086 (políticas de desconto por perfil, regra a ser combinada sem duplicação), TASK-087 (campanhas promocionais, regra a ser combinada sem duplicação)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar um motor de regras comerciais extensível que combine condições por cliente, produto, canal e período (ex.: desconto progressivo por volume, condição especial por segmento de cliente), evoluindo TASK-086/TASK-087 sem duplicar lógica já existente no motor de precificação base (TASK-088).

## Escopo técnico

- Modelar `CommercialRule` genérica (tipo: desconto progressivo, condição por segmento, combo de produtos, canal específico; condições: cliente/segmento, produto/categoria/coleção, canal, período de vigência; efeito: percentual, valor fixo, condição de pagamento).
- Estender o motor de precificação server-side (TASK-088) para consultar e aplicar `CommercialRule` na mesma pipeline de cálculo de preço/desconto — nunca criar um segundo motor de cálculo paralelo e divergente.
- Resolver conflito/prioridade entre regras sobrepostas (ex.: desconto por perfil de TASK-086 vs. desconto progressivo por volume) com ordem de precedência explícita e documentada, sempre determinística.
- Tela administrativa de simulação de regra: permite ao gestor testar uma regra nova contra pedidos/cenários hipotéticos antes de ativá-la, sem afetar pedidos reais.
- Log de aplicação de regra por pedido (quais `CommercialRule` foram usadas e em que ordem), reaproveitando a auditabilidade já exigida do motor de precificação.

## Regras de negócio e restrições

- Toda regra comercial avançada é avaliada dentro da mesma Cloud Function de precificação, nunca em uma segunda fonte de cálculo divergente no cliente ou em outra function isolada sem coordenação.
- Precedência entre regras sobrepostas é determinística e documentada — o mesmo pedido, nas mesmas condições, deve sempre produzir o mesmo resultado.
- Regras com período de vigência expirado nunca são aplicadas retroativamente nem continuam válidas após o fim da vigência.
- Simulação de regra nunca persiste efeito em pedidos reais nem em dados de clientes reais.
- Toda regra ativa deve ser auditável: dado um pedido, deve ser possível explicar exatamente quais regras foram avaliadas e quais foram aplicadas.

## Testes obrigatórios

- Testes unitários do motor: regra única, regras sobrepostas com prioridade definida, regra fora de vigência, regra por canal não aplicável ao canal do pedido.
- Testes de regressão garantindo que TASK-086/TASK-087 continuam funcionando dentro do motor estendido (sem duplicação de lógica).
- Testes de simulação: nenhuma alteração persistida em pedidos/clientes reais.
- Testes de auditoria: log de regras aplicadas por pedido é completo e correto.

## Critérios de aceite

- Regras comerciais avançadas são avaliadas dentro do motor de precificação único, sem lógica duplicada em outro lugar.
- Resultado do cálculo é determinístico e auditável para qualquer combinação de regras.
- Simulação de regra nunca afeta dados reais.
- Regras fora de vigência nunca são aplicadas.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
