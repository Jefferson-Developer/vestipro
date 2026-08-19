# TASK-145 — Implementar visualizações salvas e compartilhadas

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ⬜ Pendente
**Depende de:** TASK-144 (construtor de relatórios, fonte da `ReportDefinition` que será salva)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o usuário salve uma construção de relatório (TASK-144) como visualização favorita,
privada ou compartilhada com a equipe conforme sua permissão, para reexecução rápida sem remontar a
consulta do zero.

## Escopo técnico

- Modelar `SavedReport` (domínio/DTO) mapeando para
  `organizations/{organizationId}/savedReports/{reportId}`, contendo a `ReportDefinition` (TASK-144)
  mais metadados: nome, dono, visibilidade, criadoEm, atualizadoEm.
- Casos de uso: `SaveReportView`, `UpdateSavedReport`, `DeleteSavedReport`,
  `ListSavedReports` (próprios + compartilhados com o usuário).
- Campo de visibilidade `private | team | organization`; alterar para `team`/`organization` exige
  permissão explícita (ex.: `SALES_MANAGER`, `ADMIN`, `OWNER` ou permissão dedicada de
  compartilhamento).
- UI: lista "Meus relatórios" e "Compartilhados comigo", ação de favoritar, renomear, duplicar e
  excluir (com diálogo de confirmação para exclusão).
- Sincronizar apenas metadados (nome, favorito, visibilidade) — a execução de dados é sempre
  recalculada via TASK-144/TASK-133, nunca cacheada como se fosse a definição salva.

## Regras de negócio e restrições

- Apenas o dono ou perfis `ADMIN`/`OWNER` podem editar/excluir uma visualização compartilhada;
  demais usuários com acesso apenas visualizam/executam.
- Executar uma visualização compartilhada sempre respeita o RBAC de quem está executando — dois
  usuários podem obter resultados diferentes da mesma visualização conforme escopo de carteira.
- Excluir uma visualização referenciada por um agendamento ativo (TASK-149) exige aviso explícito ou
  bloqueio, nunca falha silenciosa do agendamento dependente.
- Nome de visualização único por usuário, para evitar duplicidade confusa na lista de favoritos.

## Testes obrigatórios

- Teste de caso de uso: salvar privado, salvar compartilhado, tentar editar visualização
  compartilhada sem permissão (deve falhar com `PermissionFailure`).
- Teste de RBAC: `SALES_REP` compartilha no máximo com a própria equipe, não com toda a organização.
- Teste de bloc para listagem combinando "meus" e "compartilhados", incluindo estado vazio e erro de
  rede.
- Teste da regra que impede exclusão silenciosa de relatório referenciado por agendamento ativo.
- Teste de isolamento multi-tenant (visualização de uma organização nunca aparece em outra).

## Critérios de aceite

- Usuário salva um relatório com um clique e o reencontra na lista de favoritos.
- Compartilhamento respeita a permissão do usuário e a visibilidade escolhida no momento de salvar.
- Execução de uma visualização compartilhada reflete sempre o RBAC de quem executa, nunca o do dono.
- Exclusão de visualização vinculada a agendamento ativo é tratada com aviso ou bloqueio explícito.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
