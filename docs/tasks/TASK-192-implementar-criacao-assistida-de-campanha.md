# TASK-192 — Implementar criação assistida de coleção/campanha (IA generativa)

**Epic:** EPIC-28 — Inteligência Artificial Generativa
**Status:** ⬜ Pendente
**Depende de:** TASK-080 (lookbook e campanhas visuais, tela onde a sugestão será oferecida), TASK-087 (campanhas promocionais, estrutura de campanha a ser preenchida com o texto sugerido)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Auxiliar o admin/gestor a criar rapidamente a estrutura e os textos de uma coleção/campanha (nome, descrição, público-alvo sugerido, período) a partir de parâmetros informados (produtos selecionados, público, período), sempre como rascunho revisável antes de publicar — nunca publicando automaticamente.

## Escopo técnico

- Cloud Function `assistCampaignCreation` recebe parâmetros estruturados informados pelo admin (lista de productIds/coleção, público-alvo, período, tom de comunicação desejado) e gera texto/estrutura sugerida (nome da campanha, descrição, headline) via LLM.
- Prompt restrito aos parâmetros fornecidos e aos dados reais dos produtos selecionados (nome, categoria, coleção) — proibido inventar características de produto não cadastradas.
- Tela de criação de campanha/lookbook (TASK-080/TASK-087) ganha ação "Gerar sugestão com IA", preenchendo campos de texto como rascunho editável, nunca publicando diretamente.
- Validação pós-geração: qualquer nome de produto/atributo citado no texto deve existir nos dados fornecidos; texto reprovado é descartado/regenerado.
- Registrar quando uma campanha foi criada com apoio de sugestão de IA (flag/analytics), para acompanhamento de adoção.

## Regras de negócio e restrições

- Toda sugestão é editável e exige revisão humana explícita antes da publicação, reaproveitando o fluxo de publicação já existente de campanhas/lookbook com aprovação final do admin.
- Geração nunca cria preço, desconto ou condição comercial — isso permanece em TASK-087/motor de precificação.
- Payload enviado ao modelo restrito aos dados da organização do admin autenticado.
- Texto gerado deve seguir as diretrizes de marca/tom já configuradas pela organização, quando existirem.

## Testes obrigatórios

- Testes da Cloud Function: geração com produtos válidos, produto sem dados suficientes, rejeição de texto com atributo inventado.
- Teste de isolamento multi-tenant do payload de produtos.
- Testes de widget: geração de sugestão, edição do rascunho, publicação exigindo confirmação humana, erro de geração.
- Teste garantindo que nenhuma sugestão inclui preço/desconto.

## Critérios de aceite

- Admin consegue gerar rascunho de campanha/coleção a partir de parâmetros reais e sempre revisa antes de publicar.
- Nenhum texto gerado cita produto/atributo fora dos dados fornecidos.
- Nenhuma sugestão inclui preço ou desconto.
- Uso da IA na criação fica identificável para acompanhamento interno.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
