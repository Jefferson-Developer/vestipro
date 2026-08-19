# TASK-096 — Implementar pedido em rascunho

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-095 — Modelar Order e OrderItem (rascunho é uma `Order` em status `draft`); TASK-051 — Implementar carteira de clientes (seleção de cliente para iniciar o pedido)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o vendedor inicie uma venda associada a um cliente da carteira, funcionando 100% offline, com salvamento automático de rascunho — sem nenhuma dependência de conectividade para começar ou continuar um pedido.

## Escopo técnico

- Criar o fluxo de criação de `Order` em status `draft` a partir da carteira de clientes (TASK-051): o vendedor seleciona um cliente e o sistema pré-preenche empresa/unidade/tabela de preço padrão conforme regras já vigentes no cadastro do cliente.
- Persistir o rascunho localmente (Drift) imediatamente ao iniciar, sem exigir nenhuma chamada de rede para criar ou editar um rascunho.
- Implementar autosave (com debounce) a cada alteração relevante (cliente, item, quantidade, observação), preservando o estado ao trocar de tela ou fechar o app.
- Criar BLoC dedicado ao ciclo de vida do rascunho (ex.: `OrderDraftBloc`) com eventos como `OrderDraftStarted`, `OrderDraftCustomerSelected`, `OrderDraftAutoSaved`.
- Criar a tela inicial de "novo pedido": seleção de cliente (reaproveitando a busca da carteira), resumo do que será pré-preenchido e CTA para avançar à adição de produtos.

## Regras de negócio e restrições

- O cliente selecionado deve pertencer à carteira do vendedor autenticado (ou ele ter permissão explícita) — validado tanto na UI (ocultar) quanto no domain/Functions.
- O rascunho nunca pode ser perdido por falta de conexão; falha de autosave local deve ser tratada como erro recuperável, nunca silenciosa.
- O rascunho não gera nenhum efeito em estoque/reserva/saldo (isso só ocorre em fases posteriores, conforme feature flag de reserva comercial da TASK-092).

## Testes obrigatórios

- Teste de BLoC cobrindo criação, autosave e recuperação de rascunho após reinício simulado do app.
- Teste offline: criação e edição de rascunho sem conectividade simulada (mock de `connectivity_plus`).
- Teste de widget cobrindo seleção de cliente e estados de loading/vazio/erro na busca da carteira.
- Teste garantindo que cliente fora da carteira do vendedor não aparece/não pode ser selecionado sem permissão explícita.

## Critérios de aceite

- Vendedor consegue iniciar um pedido a partir de um cliente da carteira totalmente offline.
- Rascunho é salvo automaticamente sem ação explícita do usuário e sobrevive ao fechamento do app.
- Nenhuma chamada de rede é obrigatória para iniciar ou editar um rascunho.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
