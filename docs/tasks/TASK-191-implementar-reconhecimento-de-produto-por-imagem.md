# TASK-191 — Implementar reconhecimento de produto por imagem

**Epic:** EPIC-28 — Inteligência Artificial Generativa
**Status:** ⬜ Pendente
**Depende de:** TASK-065 (cadastro/edição de produto, fonte das imagens de catálogo a serem indexadas)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Permitir identificar um produto do catálogo a partir de uma foto tirada pelo vendedor ou cliente (ex.: peça física em uma vitrine), tratando corretamente casos de baixa confiança — sugerindo candidatos em vez de afirmar uma única resposta possivelmente errada.

## Escopo técnico

- Cloud Function `recognizeProductImage` que recebe a imagem (via Storage) e chama um serviço de visão computacional/embedding de imagem, comparando contra os embeddings pré-calculados das imagens de produto cadastradas (TASK-065).
- Job de indexação (batch/trigger no upload de imagem de produto) que gera e mantém o índice de embeddings por produto/variante, escopado por organização.
- Retorno estruturado com lista de candidatos ordenados por score de similaridade (nunca um único resultado definitivo) e um limiar mínimo de confiança abaixo do qual nenhum candidato é sugerido.
- Tela "Identificar produto por foto": captura via `image_picker`, exibe lista de candidatos com imagem/nome/score, ação de abrir o produto ou "nenhum destes" para nova tentativa/refino manual.
- Registrar evento de uso e feedback do usuário ("era este" / "não era nenhum") para acompanhar a qualidade do reconhecimento ao longo do tempo.

## Regras de negócio e restrições

- Nunca abrir automaticamente um único produto como se fosse certeza; sempre exigir confirmação do usuário entre os candidatos.
- Abaixo do limiar mínimo de confiança, exibir explicitamente "não foi possível identificar com confiança" em vez de forçar um palpite.
- Índice de embeddings e busca escopados por organização — nunca comparar imagem contra catálogo de outro tenant.
- Imagem capturada pelo usuário não é retida além do necessário para o processamento (política de retenção documentada).

## Testes obrigatórios

- Testes da Cloud Function: imagem com correspondência clara, correspondência ambígua (candidatos próximos), sem correspondência (abaixo do limiar), imagem inválida/corrompida.
- Teste de isolamento multi-tenant do índice de embeddings.
- Testes de widget: fluxo de captura, lista de candidatos, "nenhum destes", estado de baixa confiança, erro de rede.
- Teste do registro de feedback de acerto/erro.

## Critérios de aceite

- Reconhecimento sempre apresenta candidatos com confiança, nunca uma única resposta forçada.
- Abaixo do limiar de confiança definido, o sistema comunica isso claramente ao usuário.
- Nenhuma busca de imagem cruza dados entre organizações.
- Feedback do usuário sobre acerto/erro é registrado para acompanhamento de qualidade.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
