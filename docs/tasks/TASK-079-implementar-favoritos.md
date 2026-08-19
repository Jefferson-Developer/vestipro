# TASK-079 — Implementar favoritos

**Epic:** EPIC-10 — Catálogo Premium
**Status:** ⬜ Pendente
**Depende de:** TASK-072 (variantes produto-cor-tamanho, necessárias para favoritar um produto/variante específico)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o vendedor salve produtos para consulta posterior durante uma visita ou negociação,
com funcionamento garantido tanto online quanto offline. Favoritos são pessoais por usuário (não
compartilhados entre a equipe) e devem sincronizar de forma confiável quando a conexão voltar.

## Escopo técnico

- Modelar entidade `FavoriteProduct` (`productId`, `userId`, `organizationId`, `companyId`,
  `createdAt`, `syncStatus`) seguindo o padrão de entidade sincronizável (Outbox) definido pelo
  `flutter-senior-architect`.
- Persistir favoritos localmente (Drift) como fonte imediata de leitura/escrita; sincronizar com
  Firestore em background via Outbox, sem bloquear a ação de favoritar/desfavoritar na UI.
- Adicionar botão de favoritar no card de produto (grid) e no detalhe de produto, reutilizando o
  mesmo componente visual em ambos os contextos.
- Criar tela "Favoritos" com o mesmo grid visual de produtos (TASK-077), filtrando por itens
  favoritados do usuário atual.
- Registrar evento de analytics ao favoritar/desfavoritar (ex.: `product_favorited`,
  `product_unfavorited`), sem violar a regra de não misturar métricas administrativas com
  comerciais.

## Regras de negócio e restrições

- Favoritar/desfavoritar deve refletir imediatamente na UI (otimista), independente de haver
  conexão no momento.
- Um produto removido/descontinuado ou sem disponibilidade na organização deve ser tratado
  explicitamente na tela de favoritos (nunca card quebrado).
- Favoritos são escopados por usuário e por organização — nunca vazar favoritos entre organizações
  ou entre usuários diferentes.
- Ação de favoritar não pode duplicar registro ao ser tocada repetidamente antes da sincronização.

## Testes obrigatórios

- Testes de repositório/datasource local: favoritar, desfavoritar, favoritar já favoritado
  (idempotência), listar favoritos vazio, listar com paginação.
- Testes de sincronização: favorito criado offline sincroniza ao reconectar; falha de sincronização
  é recuperável e não perde o dado local.
- Testes de widget: estado do ícone de favorito refletindo corretamente o status local, tela de
  favoritos vazia com estado explicativo, tela de favoritos com produto indisponível.
- Teste de isolamento multi-tenant garantindo que favoritos de uma organização não aparecem em
  outra.

## Critérios de aceite

- Favoritar/desfavoritar funciona sem conexão e sincroniza de forma transparente ao reconectar.
- Tela de favoritos reutiliza o grid visual padrão do catálogo, sem componente duplicado.
- Nenhuma duplicação de favorito ocorre mesmo com toques repetidos ou uso offline prolongado.
- Estado vazio da tela de favoritos orienta o vendedor a favoritar produtos a partir do catálogo.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
