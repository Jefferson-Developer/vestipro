# TASK-160 — Implementar retenção configurável e minimização de dados

**Epic:** EPIC-20 — LGPD e Privacidade
**Status:** ⬜ Pendente
**Depende de:** TASK-013 (Configurar Cloud Firestore, onde reside a maior parte dos dados sujeitos a
retenção)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar uma política de retenção configurável por tipo de dado e por organização, além de
revisar todos os pontos de coleta de dado pessoal do app para garantir minimização — nunca coletar
ou armazenar dado pessoal além do necessário para a funcionalidade que o utiliza.

## Escopo técnico

- Modelar `DataRetentionPolicy` configurável por organização e por tipo de dado (ex.: logs de
  auditoria, notificações lidas, dados de localização de check-in, exportações temporárias no
  Storage).
- Cloud Function agendada (Cloud Scheduler) que aplica a política: expira/anonimiza/remove dados
  além do prazo configurado por tipo.
- Revisar todos os pontos de coleta de dado pessoal do app (autenticação, localização, preferências,
  analytics) aplicando minimização: nunca coletar/persistir campo além do estritamente necessário
  para a funcionalidade que o usa.
- Documentar, a nível de código (comentário técnico junto à entidade/DTO, não markdown solto), quais
  campos são pessoais e por que são coletados, para apoiar auditorias futuras.

## Regras de negócio e restrições

- Prazo padrão seguro quando a organização não configurou explicitamente (nunca "reter para sempre"
  por omissão).
- Retenção de dados com obrigação legal (ex.: fiscal) nunca é reduzida abaixo do prazo mínimo legal,
  mesmo que a organização tente configurar um valor menor (validação server-side do limite mínimo).
- Minimização é revisada a cada nova coleta de dado adicionada ao app (checklist de referência para
  futuras tasks que envolvam Auth/CRM/localização).
- Aplicação da política de retenção nunca remove dado ainda referenciado por processo ativo (ex.:
  notificação de um agendamento em andamento).

## Testes obrigatórios

- Teste da Function no Emulator: dado além do prazo configurado é expirado/anonimizado corretamente
  por tipo.
- Teste garantindo que o prazo mínimo legal não pode ser configurado abaixo do limite permitido.
- Teste do prazo padrão seguro aplicado quando a organização não configurou a política.
- Teste garantindo que dado ainda em uso ativo não é removido precocemente.
- Teste de minimização: nenhum campo pessoal novo é persistido sem justificativa/uso real (revisão de
  contrato de dados coletados).

## Critérios de aceite

- Cada organização configura prazos de retenção por tipo de dado dentro dos limites legais mínimos.
- Dados pessoais além do prazo são expirados/anonimizados automaticamente, sem intervenção manual.
- Nenhum dado pessoal é coletado ou armazenado além do necessário para a funcionalidade
  correspondente.
- Processo de retenção nunca remove dado ainda em uso ativo por outra funcionalidade.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
