# TASK-187 — Implementar IA generativa: sugestão de abordagem comercial por cliente

**Epic:** EPIC-28 — Inteligência Artificial Generativa
**Status:** ⬜ Pendente
**Depende de:** TASK-063 (próxima melhor ação, base de lógica e dados a ser estendida para gerar texto de abordagem)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Gerar uma sugestão de abordagem comercial personalizada por cliente, a partir do histórico real do cliente (compras, atividades de CRM, insights ativos), sempre editável pelo vendedor antes de qualquer uso em contato real — nunca enviada automaticamente ao cliente.

## Escopo técnico

- Cloud Function `suggestApproach` reaproveita/estende a lógica de "próxima melhor ação" (TASK-063), montando um payload estruturado: últimas compras, atividades CRM recentes, insights ativos do cliente, motivo de perda/ganho recente quando houver.
- Prompt template restringe o modelo a gerar um roteiro de abordagem citando apenas fatos presentes no payload — proibido introduzir promessas, descontos ou dados não fornecidos.
- Botão "Sugerir abordagem" na tela do cliente (detalhe 360º, TASK-052) e na central de oportunidades (TASK-132), abrindo o texto sugerido em campo editável antes de qualquer uso (nota, WhatsApp, ligação).
- Validação pós-geração análoga à TASK-186: qualquer valor numérico ou nome de produto citado deve existir no payload; caso contrário, a resposta é descartada/regenerada.
- Registrar no histórico do cliente (timeline CRM) quando uma sugestão foi usada como base de uma atividade, para rastreabilidade.

## Regras de negócio e restrições

- A sugestão é sempre um rascunho editável; nunca dispara mensagem ou ação automaticamente.
- Nunca sugerir desconto, condição comercial ou preço — isso é responsabilidade exclusiva do motor de precificação/políticas comerciais.
- Payload restrito ao cliente e à organização do vendedor autenticado; nunca comparação cruzada com dados de outro tenant.
- O texto gerado deve evitar linguagem que pareça compromisso contratual da empresa.

## Testes obrigatórios

- Testes da Cloud Function: geração com histórico rico, histórico mínimo, cliente sem atividades, rejeição de resposta com dado fora do payload.
- Teste garantindo que o texto sugerido nunca contém termos de desconto/preço não fornecidos.
- Teste de isolamento multi-tenant do payload.
- Testes de widget: edição do texto sugerido, uso da sugestão como base de atividade CRM, estados de erro/carregando.

## Critérios de aceite

- Vendedor sempre pode editar a sugestão antes de usá-la.
- Nenhuma sugestão cita fato, produto ou número fora do histórico real do cliente.
- Nenhuma sugestão inclui preço/desconto.
- Uso da sugestão fica rastreável na timeline do cliente.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
