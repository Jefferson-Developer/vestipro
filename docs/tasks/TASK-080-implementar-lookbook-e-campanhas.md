# TASK-080 — Implementar lookbook e campanhas visuais

**Epic:** EPIC-10 — Catálogo Premium
**Status:** ⬜ Pendente
**Depende de:** TASK-066 (coleções e estações, unidade de agrupamento das campanhas e lookbooks)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar narrativas visuais por coleção/campanha (lookbook) — imagens editoriais, texto e
produtos relacionados — configuráveis por um administrador via painel de gestão de conteúdo, sem
exigir novo deploy do aplicativo para publicar ou atualizar uma campanha.

## Escopo técnico

- Modelar entidade `Campaign`/`Lookbook` (título, período de vigência, imagens de capa/editoriais,
  texto descritivo, coleção associada, lista de produtos relacionados, status
  ativo/agendado/expirado) no Firestore, escopada por organização/empresa.
- Criar tela administrativa (Web/desktop) de cadastro/edição de campanha: upload e reordenação de
  imagens, seleção de produtos relacionados via busca do catálogo, definição de período de
  vigência.
- Criar a tela de consumo do lookbook (mobile/tablet/desktop) com layout editorial (imagem grande,
  texto, carrossel de produtos relacionados usando o `ProductCard` padrão).
- Implementar resolução de vigência: campanha só aparece no catálogo enquanto dentro do período
  configurado; expiração não depende de o cliente forçar um refresh manual (checagem client-side
  na leitura + campo de status mantido no servidor).
- Adicionar como uma das seções possíveis da home do catálogo (TASK-076) e como modo de
  visualização "catálogo por campanha" (TASK-082).
- Registrar eventos `campaign_viewed` e `campaign_product_clicked`.

## Regras de negócio e restrições

- Conteúdo de campanha deve ser 100% orientado a dados (Firestore/Storage) — nenhuma campanha
  hardcoded no código do app.
- Produtos relacionados de uma campanha expirada não devem continuar aparecendo como "em campanha"
  em nenhuma tela.
- Upload de imagem segue as mesmas regras de compressão, formato e reordenação do restante do
  catálogo (ver TASK-068).
- Edição/publicação de campanha respeita RBAC (perfis administrativos), nunca disponível para
  `SALES_REP`/`SALES_ASSISTANT` sem permissão explícita.

## Testes obrigatórios

- Testes de domínio/repositório: campanha ativa, agendada (ainda não iniciada), expirada, sem
  produtos relacionados, com imagem ausente.
- Testes de widget/golden: layout editorial em mobile, tablet e desktop; carrossel de produtos
  relacionados; estado de campanha sem conteúdo publicado.
- Teste de RBAC negando acesso à tela administrativa de campanha para perfil sem permissão.
- Teste garantindo que uma campanha expirada some do catálogo sem exigir atualização do app.
- Teste de analytics dos eventos `campaign_viewed` e `campaign_product_clicked`.

## Critérios de aceite

- Um administrador publica ou atualiza uma campanha e ela aparece no app sem novo build/deploy.
- Campanha fora do período de vigência não é exibida em nenhuma tela do catálogo.
- Lookbook mantém identidade visual premium consistente com o Design System, sem cor/tipografia
  arbitrária.
- Tela administrativa de campanha respeita RBAC e trata estados de loading/erro/vazio.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
