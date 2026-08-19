# TASK-081 — Implementar compartilhamento de catálogo

**Epic:** EPIC-10 — Catálogo Premium
**Status:** ⬜ Pendente
**Depende de:** TASK-077 (grid visual de produtos, base da tela de seleção a ser compartilhada)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o vendedor compartilhe produtos ou uma seleção de produtos com um cliente por meio de
um link controlado, gerado por Cloud Function, com validade definida — e, quando possível, medir se
o cliente abriu o link. É o primeiro passo em direção ao portal B2B (EPIC-25).

## Escopo técnico

- Criar Cloud Function `createCatalogShareLink` que gera um token de compartilhamento (produto
  único, lista de produtos ou coleção) com `organizationId`, `createdBy`, `expiresAt` e escopo de
  visualização — nunca gerar o link/token no cliente.
- Modelar `CatalogShare` (Firestore) com status (ativo, expirado, revogado), lista de itens
  referenciados e contador de aberturas.
- Implementar tela pública/leve (Flutter Web) de visualização do link compartilhado, somente
  leitura, sem exigir login do cliente, respeitando o escopo e a validade do token.
- Registrar abertura do link (Cloud Function `registerShareOpen` ou trigger de Firestore) e expor
  esse dado ao vendedor na tela de origem do compartilhamento ("visualizado em ...").
- Adicionar ação "Compartilhar" no grid/detalhe de produto e em uma seleção multi-item, usando o
  compartilhamento nativo da plataforma para enviar o link (ex.: WhatsApp, e-mail).
- Registrar eventos `catalog_share_created` e `catalog_share_opened`.

## Regras de negócio e restrições

- Geração e validação do token/link são sempre server-side; o cliente nunca decide sozinho o que o
  link expõe ou por quanto tempo.
- Link expirado ou revogado deve exibir mensagem clara ao destinatário, nunca erro técnico cru.
- Tela pública de visualização nunca expõe dados de outros clientes, pedidos, preços de tabelas às
  quais o destinatário não tem direito ou informações internas da organização além do escopo
  definido.
- Contagem de abertura é best-effort (analytics) e nunca deve bloquear o acesso do destinatário em
  caso de falha no registro.

## Testes obrigatórios

- Testes da Cloud Function: geração de link com escopo válido, expiração respeitada, revogação,
  tentativa de acesso após expiração/revogação.
- Testes de segurança (Firestore Rules no Emulator Suite): destinatário não autenticado só lê o que
  o escopo do share permite; nenhuma outra coleção fica acessível via o mesmo token.
- Testes de widget: tela pública com produto disponível, produto indisponível, link expirado, link
  revogado, estado de erro de rede.
- Teste de analytics dos eventos `catalog_share_created` e `catalog_share_opened`.

## Critérios de aceite

- Vendedor gera um link a partir do catálogo e o destinatário consegue visualizar os produtos sem
  login, dentro do escopo e da validade definidos.
- Link expirado/revogado nunca expõe conteúdo do catálogo.
- Vendedor consegue ver, na origem do compartilhamento, se e quando o link foi aberto (quando o
  registro de abertura for tecnicamente possível).
- Nenhuma regra de geração/validade do link depende exclusivamente do cliente.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
