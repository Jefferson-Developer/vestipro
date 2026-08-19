# TASK-154 — Implementar preferências de comunicação

**Epic:** EPIC-19 — Notificações e Engajamento
**Status:** ⬜ Pendente
**Depende de:** TASK-151 (central de notificações internas, cujos geradores devem respeitar estas
preferências)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o usuário controle canal e frequência de notificação por categoria (CRM, comercial,
sistema), com a preferência sincronizada entre todos os seus dispositivos, evitando fadiga de
notificação sem comprometer alertas essenciais.

## Escopo técnico

- Modelar `CommunicationPreferences` por usuário: categoria (CRM, comercial, sistema) × canal (push,
  e-mail, central interna) × frequência (imediato, resumo diário, desativado).
- Tela de preferências no Design System (formulário com toggles/seletor de frequência por
  categoria).
- Persistir a preferência em Firestore como fonte única de verdade, sincronizando entre dispositivos
  do mesmo usuário (não apenas localmente).
- Todo gerador de notificação (TASK-152, TASK-153, TASK-155) deve consultar estas preferências antes
  de enviar.

## Regras de negócio e restrições

- Notificações críticas de sistema (ex.: segurança, sessão expirada) não podem ser completamente
  desativadas — apenas o canal pode ser ajustado dentro de limites seguros.
- Alteração de preferência em um dispositivo reflete nos demais em tempo hábil (sincronização real,
  não apenas local).
- Preferência ausente (usuário nunca configurou) tem um padrão seguro documentado (ex.: push ativado
  para CRM/comercial, e-mail desativado por padrão).

## Testes obrigatórios

- Teste de caso de uso: salvar preferência, ler valor padrão quando ausente, impedir desativação
  completa de categoria crítica de sistema.
- Teste de sincronização entre dispositivos simulados observando a mesma preferência.
- Teste de integração: gerador de notificação respeita preferência desativada (não dispara push).
- Teste de widget: formulário de preferências com estados de salvar, erro e sucesso.
- Teste de RBAC/multi-tenant (preferência de um usuário nunca vaza para outro).

## Critérios de aceite

- Usuário configura canal e frequência por categoria, e a alteração vale para todos os seus
  dispositivos.
- Categorias críticas de sistema mantêm um mínimo de canal ativo garantido.
- Todo envio de notificação respeita a preferência vigente no momento do envio.
- Preferência padrão está documentada e é aplicada quando o usuário nunca configurou nada.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
