# TASK-204 — Implementar logs de auditoria exportáveis

**Epic:** EPIC-31 — Administração Avançada e Data Platform
**Status:** ⬜ Pendente
**Depende de:** TASK-033 (auditoria administrativa, fonte dos registros a serem exportados)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir exportar o audit log central (TASK-033) em CSV/PDF para fins de compliance, com filtros por período/organização/ator e controle de acesso restrito a quem tem permissão explícita para essa exportação.

## Escopo técnico

- Cloud Function `exportAuditLog` que gera o arquivo (CSV via biblioteca já usada em EPIC-18, PDF reaproveitando a exportação PDF de relatórios) a partir de uma consulta filtrada (período, organização, ator, tipo de ação) sobre o audit log existente.
- RBAC dedicado para exportação (ex.: apenas `OWNER`/`ADMIN` da organização para o log da própria organização; operador VestiPro para logs multi-organização, dentro do escopo de TASK-203), validado server-side.
- Tela de exportação com seleção de filtros, pré-visualização de quantidade de registros antes de gerar, e histórico de exportações realizadas (quem exportou, quando, quais filtros) — a própria exportação gera um evento de auditoria.
- Limitar volume por exportação (paginação/streaming do arquivo) para evitar exportações gigantes travando a function ou o cliente.
- Entrega do arquivo via link temporário e seguro (Storage com regra de expiração), nunca anexado diretamente em resposta sem controle de acesso.

## Regras de negócio e restrições

- Exportação de log de auditoria é, ela própria, uma ação sensível e deve gerar uma nova entrada no audit log (quem exportou o quê).
- Filtros de organização respeitam RBAC: um admin de organização nunca exporta log de outra organização.
- Link de download do arquivo exportado expira e é de acesso único/restrito, seguindo o mesmo cuidado de segurança de outros links sensíveis do sistema (ex.: TASK-081).
- Exportação não pode alterar nem mascarar incorretamente os dados originais do log — deve ser fiel ao registrado.

## Testes obrigatórios

- Testes da Cloud Function: exportação CSV e PDF com filtros diversos, volume grande (paginação/streaming), filtro sem resultados.
- Testes de RBAC: admin de uma organização não consegue exportar log de outra; operador VestiPro dentro do escopo de TASK-203.
- Teste garantindo que a própria exportação gera uma entrada de auditoria.
- Testes de segurança do link de download (expiração, acesso restrito).

## Critérios de aceite

- Exportação em CSV/PDF reflete fielmente os registros filtrados do audit log.
- Nenhum usuário exporta log de auditoria fora do escopo permitido pelo seu RBAC.
- Toda exportação realizada fica, ela própria, registrada no audit log.
- Link de download do arquivo exportado é temporário e de acesso controlado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
