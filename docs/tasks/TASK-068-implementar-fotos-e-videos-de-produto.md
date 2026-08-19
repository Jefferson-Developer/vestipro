# TASK-068 — Implementar fotos e vídeos de produto

**Epic:** EPIC-08 — Produtos e Catálogo Base
**Status:** ⬜ Pendente
**Depende de:** TASK-065 (Implementar cadastro/edição de produto) — a galeria é parte do formulário de produto; TASK-014 (Configurar Firebase Storage) — fornece o bucket e as regras de acesso usadas no upload.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar upload de fotos e vídeos de produto para o Firebase Storage com compressão prévia, geração de thumbnails, reordenação de mídia, definição de imagem principal e suporte a vídeo curto de produto, respeitando o isolamento multi-tenant no armazenamento.

## Escopo técnico

- Implementar upload para Firebase Storage com compressão via `flutter_image_compress` antes do envio, reduzindo tamanho sem perda perceptível de qualidade.
- Gerar thumbnails (no cliente durante a compressão e/ou via Cloud Function no upload) para uso em cards e listas, nunca carregando a imagem original em telas de grid.
- Implementar reordenação de imagens (drag-and-drop no Web, ação explícita/long-press no mobile) e definição de imagem principal do produto.
- Implementar suporte a vídeo curto de produto: upload, limite de tamanho/duração configurável por organização, player com controles básicos.
- Criar entidade `ProductMedia` (tipo foto/vídeo, url, thumbnailUrl, ordem, `principal: bool`, `colorId` opcional para foto específica de uma cor, integrando com TASK-070).
- Exibir progresso de upload sem bloquear a tela inteira, permitindo cancelamento do upload em andamento.

## Regras de negócio e restrições

- Produto não pode sair do status rascunho sem ao menos uma imagem principal definida (conforme regra de completude da TASK-065).
- Excluir a imagem principal exige escolher outra automaticamente como principal ou bloquear a exclusão até haver substituta.
- Vídeo respeita limite de tamanho/duração configurável por organização; upload fora do limite é rejeitado com mensagem clara antes de transferir o arquivo inteiro.
- Nenhuma imagem/vídeo pode ficar acessível fora da organização dona do produto — validado via Storage Security Rules.

## Testes obrigatórios

- Teste de widget da galeria cobrindo reordenação e definição de imagem principal.
- Testes unitários do fluxo de compressão/validação de formato antes do upload (com mock do serviço de storage).
- Teste de integração com Firebase Emulator validando Storage Rules positiva e negativamente para upload de mídia de produto.
- Teste cobrindo cancelamento de upload em andamento e exclusão da imagem principal.

## Critérios de aceite

- Upload com compressão e geração de thumbnail funcionando de ponta a ponta.
- Reordenação e definição de imagem principal funcionais e persistidas.
- Vídeo curto suportado com validação de limite de tamanho/duração.
- Storage Rules testadas positiva e negativamente; `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
