# TASK-088 — Implementar motor de precificação server-side

**Epic:** EPIC-11 — Tabelas de Preço e Condições Comerciais
**Status:** ⬜ Pendente
**Depende de:** TASK-083 (Price List), TASK-084 (preço por produto/variante), TASK-086 (políticas de desconto), TASK-087 (campanhas promocionais) — o motor centraliza e compõe o resultado de todas essas regras

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Centralizar em uma Cloud Function idempotente o cálculo definitivo de preço, desconto, condição de
pagamento e total de um pedido, compondo Price List, preço por variante, política de desconto por
perfil e campanhas promocionais. O cálculo client-side existente na UI serve apenas como feedback
imediato de UX e nunca é a fonte de verdade — todo pedido é revalidado e recalculado no servidor
antes de ser aceito.

## Escopo técnico

- Criar Cloud Function `calculatePricing` (idempotente, com chave de idempotência por
  requisição/pedido) que recebe cliente, empresa/unidade, itens (produto/variante/quantidade),
  Price List selecionada e condição de pagamento, e retorna preço unitário resolvido, descontos
  aplicados (com origem: política de perfil, campanha, manual), frete e total final por item e do
  pedido.
- Implementar a composição de regras na ordem documentada e testada: resolução de preço-base
  (TASK-083/TASK-084) → aplicação de campanhas elegíveis (TASK-087) → validação/aplicação de limite
  de desconto por perfil (TASK-086) → condição de pagamento (TASK-085) → totais finais.
- Expor essa mesma lógica de composição como serviço de domínio reutilizável (ex.:
  `PricingEngine` em `domain/services`), de forma que a Cloud Function e testes unitários de
  domínio compartilhem a mesma implementação central, evitando duas fontes de verdade divergentes.
- Integrar o resultado do motor à submissão de pedido (TASK-101): a Cloud Function de submissão
  chama `calculatePricing` novamente no momento do envio e rejeita o pedido se o total client-side
  divergir do total server-side além de uma tolerância de arredondamento documentada.
- Registrar log estruturado (sem dados sensíveis) de cada composição de regras aplicada, permitindo
  auditoria e depuração de por que um pedido recebeu determinado preço/desconto/total.
- Medir tempo de resposta da função via `firebase_performance`/monitoramento server-side.

## Regras de negócio e restrições

- Idempotência: chamar `calculatePricing` múltiplas vezes com os mesmos parâmetros e mesma chave de
  idempotência deve sempre retornar exatamente o mesmo resultado, mesmo sob concorrência.
- Nunca aceitar preço, desconto ou total calculado pelo cliente como valor final de um pedido —
  o valor definitivo é sempre o retornado pela função no momento da submissão.
- Composição de múltiplas regras (campanha + desconto manual + condição de pagamento) deve seguir
  ordem determinística e documentada; qualquer alteração de ordem exige atualização dos testes desta
  task.
- Divergência entre cálculo client-side e server-side acima da tolerância definida bloqueia a
  submissão do pedido com mensagem clara ao usuário (nunca falha silenciosa ou aceite automático do
  valor client-side).
- Falha em qualquer etapa da composição (ex.: Price List inexistente, produto sem preço) retorna
  erro tipado e explicável, nunca um total parcial ou incorreto.

## Testes obrigatórios

- Testes unitários do `PricingEngine` cobrindo: apenas preço-base sem desconto/campanha, desconto
  manual dentro do limite, desconto manual acima do limite (bloqueio), uma campanha aplicada,
  múltiplas campanhas concorrentes (empilhável e não empilhável), composição completa (preço +
  campanha + desconto manual + condição de pagamento).
- Testes de idempotência: mesma chamada repetida (mesmos parâmetros e idempotency key) produzindo
  resultado idêntico, inclusive sob chamadas concorrentes simuladas.
- Testes de integração com Firebase Emulator Suite: `calculatePricing` chamada end-to-end com dados
  de Price List, campanha e política de desconto reais no emulador.
- Teste de divergência: cálculo client-side simulado divergente do server-side é rejeitado na
  submissão do pedido, com mensagem clara.
- Testes de valores-limite: quantidade zero, desconto de 100%, produto sem preço em nenhuma tabela
  aplicável, cliente sem segmento elegível a nenhuma campanha.

## Critérios de aceite

- `calculatePricing` compõe corretamente Price List, preço por variante, desconto por perfil e
  campanhas, com ordem determinística documentada e testada.
- Chamadas repetidas com os mesmos parâmetros são idempotentes, inclusive sob concorrência.
- Submissão de pedido sempre revalida o preço no servidor e rejeita divergência acima da tolerância
  definida.
- Toda decisão de precificação é auditável (é possível explicar, para qualquer pedido, exatamente
  quais regras foram aplicadas e em que ordem).

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
