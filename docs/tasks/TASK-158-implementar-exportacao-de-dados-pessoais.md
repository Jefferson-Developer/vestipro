# TASK-158 — Implementar exportação de dados pessoais

**Epic:** EPIC-20 — LGPD e Privacidade
**Status:** ⬜ Pendente
**Depende de:** TASK-013 (Configurar Cloud Firestore, origem dos dados pessoais a serem exportados)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o usuário solicite e receba seus próprios dados pessoais em formato legível,
atendendo ao direito de portabilidade previsto na LGPD.

## Escopo técnico

- Caso de uso `RequestPersonalDataExport`: usuário solicita, via tela de "Privacidade", a exportação
  dos próprios dados pessoais.
- Cloud Function assíncrona que coleta os dados pessoais do usuário solicitante (perfil, vínculos de
  organização, preferências, consentimentos, atividades registradas em seu nome) e gera um arquivo
  em formato legível (ex.: JSON ou PDF estruturado).
- Disponibilizar o arquivo via link seguro e temporário no Storage, notificando o usuário (central de
  notificações, TASK-151) quando estiver pronto.
- Registrar a solicitação e sua conclusão em log de auditoria (rastreabilidade do atendimento ao
  direito de portabilidade).

## Regras de negócio e restrições

- A exportação contém apenas dados do próprio usuário solicitante — nunca dados de terceiros, mesmo
  que relacionados (ex.: nunca incluir dados pessoais de outros usuários da mesma organização).
- Link de download expira após um prazo definido e é de acesso restrito ao solicitante (validado por
  autenticação, não apenas por obscuridade da URL).
- Processo tem prazo e status visível ao usuário (solicitado, processando, pronto, expirado).
- Dados de terceiros vinculados (ex.: clientes atendidos pelo vendedor) não são dados pessoais do
  vendedor solicitante e ficam fora do escopo desta exportação.

## Testes obrigatórios

- Teste da Cloud Function no Emulator: geração do pacote de dados contendo exatamente os dados do
  solicitante.
- Teste garantindo que dados de outro usuário/terceiro nunca aparecem na exportação.
- Teste de expiração e restrição de acesso ao link de download.
- Teste do status da solicitação (solicitado → processando → pronto) refletido corretamente na UI.
- Teste de auditoria registrando a solicitação e sua conclusão.

## Critérios de aceite

- Usuário consegue solicitar e, dentro do prazo definido, baixar seus dados pessoais em formato
  legível.
- Nenhum dado de terceiro é incluído na exportação.
- Link de download é seguro, temporário e restrito ao solicitante.
- Toda solicitação fica auditável (quem pediu, quando, quando foi atendida).

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
