# TASK-200 — Implementar trocas

**Epic:** EPIC-30 — Pós-venda
**Status:** ⬜ Pendente
**Depende de:** TASK-199 (devoluções, ciclo de aprovação e auditoria reaproveitado como base)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o fluxo de troca de variante (cor/tamanho) vinculado ao pedido original, reaproveitando a base de devoluções (TASK-199) e revalidando a disponibilidade real da nova variante antes de confirmar a troca.

## Escopo técnico

- Modelar `ExchangeRequest` (orderId, item de origem/variante original, item de destino/variante nova, motivo obrigatório, status), reaproveitando o mesmo ciclo de aprovação de `ReturnRequest` (TASK-199) como base (devolução da variante antiga + saída da nova).
- Cloud Function `createExchangeRequest` valida o item original no pedido e checa em tempo real a disponibilidade da variante de destino (saldo por variante, TASK-090) antes de permitir a solicitação.
- Ao aprovar, executar como transação: reintegrar a variante original ao estoque e debitar a nova variante, revalidando preço/disponibilidade no momento da aprovação (não no momento da solicitação, que pode ter ficado desatualizado).
- Se a variante de destino deixou de estar disponível entre a solicitação e a aprovação, bloquear a aprovação automática e notificar quem está analisando para reavaliar com o cliente — nunca aprovar silenciosamente uma troca por algo indisponível.
- Tela de solicitação de troca com seleção da nova cor/tamanho já validando estoque em tempo real, e tela de análise mostrando a variante original e a solicitada lado a lado.

## Regras de negócio e restrições

- Troca nunca é aprovada sem revalidação de estoque da variante de destino no momento da aprovação.
- Diferença de preço entre a variante original e a nova (se houver) é calculada pelo motor de precificação vigente, nunca por valor congelado da solicitação.
- Todo o fluxo de aprovação, auditoria e RBAC segue o mesmo rigor de TASK-199.
- Isolamento multi-tenant idêntico ao de devoluções.

## Testes obrigatórios

- Testes da Cloud Function: troca com variante de destino disponível, indisponível na solicitação, disponível na solicitação mas indisponível na aprovação (bloqueio), cálculo de diferença de preço.
- Testes de transação: reposição da variante original e débito da nova ocorrem de forma atômica (nunca só um dos dois lados).
- Testes de RBAC e auditoria (reaproveitando o padrão de TASK-199).
- Testes de widget: seleção de nova variante com estoque em tempo real, tela de análise lado a lado, bloqueio por indisponibilidade tardia.

## Critérios de aceite

- Troca nunca é aprovada com a variante de destino indisponível no momento real da aprovação.
- Estoque da variante original e da nova são ajustados de forma atômica e correta.
- Diferença de preço, quando houver, reflete o valor vigente no momento da aprovação.
- Fluxo de auditoria e RBAC segue o mesmo padrão de rigor das devoluções.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
