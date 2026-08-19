# TASK-181 — Implementar compartilhamento de carrinho/seleção

**Epic:** EPIC-25 — Catálogo Avançado e Portal B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-081 (compartilhamento de catálogo — reaproveita a infraestrutura de link/token já criada, agora aplicada a um carrinho em elaboração, com quantidades, em vez de apenas produtos).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o vendedor compartilhe com o cliente final um carrinho/seleção de produtos em elaboração (já com quantidades por grade, ainda não submetido como pedido formal), para que o cliente revise e aprove os itens antes da submissão definitiva.

## Escopo técnico

- Estender a infraestrutura de link de compartilhamento criada em TASK-081 para suportar um carrinho com quantidades por variante (não apenas produtos/catálogo estático), preservando o mesmo padrão de token com escopo, validade e geração server-side.
- Tela pública (Flutter Web) de revisão do carrinho compartilhado: lista de itens com quantidade, preço (quando o escopo do link permite exibir preço) e total, com ações de "aprovar", "sugerir alteração" (comentário) ou "recusar item", sem exigir login do cliente final.
- Sincronizar a decisão do cliente de volta ao vendedor: quando o cliente aprova/comenta, o vendedor recebe atualização (notificação + reflexo no carrinho de origem) para então prosseguir com a submissão formal do pedido (TASK-101).
- Carrinho compartilhado permanece com o vendedor como responsável pela submissão final — a aprovação do cliente é um sinal, não um pedido em si.
- Registrar eventos de analytics equivalentes aos de TASK-081 adaptados ao carrinho (ex.: `cart_share_created`, `cart_share_reviewed`).

## Regras de negócio e restrições

- Aprovação do cliente no link não cria pedido automaticamente — apenas sinaliza concordância; a submissão formal do pedido continua exigindo a ação do vendedor dentro do app (mantendo controle de estoque/preço no momento real da submissão).
- Mesmas restrições de segurança de TASK-081 se aplicam: geração/validade do token é sempre server-side, nunca decidida pelo cliente, e a tela pública nunca expõe dados além do escopo do carrinho compartilhado.
- Preço no carrinho compartilhado só é exibido ao cliente final se a organização permitir essa exposição (parametrizável), pois nem todo processo comercial quer mostrar preço antes da negociação direta com o vendedor.
- Alteração no carrinho original pelo vendedor após o compartilhamento deve deixar claro (para o próprio vendedor) que o link compartilhado pode estar desatualizado em relação ao carrinho atual.

## Testes obrigatórios

- Teste de geração de link de carrinho com escopo, validade e (quando aplicável) exposição de preço configurável.
- Teste do fluxo de aprovação/comentário do cliente refletindo de volta no vendedor.
- Teste de segurança (Firestore Rules): destinatário não autenticado só acessa o carrinho compartilhado especificado, nada além disso.
- Teste garantindo que aprovação do cliente não cria pedido automaticamente.
- Teste de analytics dos eventos de compartilhamento/revisão de carrinho.

## Critérios de aceite

- Vendedor compartilha um carrinho em elaboração e o cliente consegue revisar/aprovar/comentar sem login.
- Aprovação do cliente nunca gera pedido sozinha — a submissão formal continua sendo ação do vendedor.
- Nenhum dado fora do escopo do carrinho compartilhado fica acessível pelo link.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
