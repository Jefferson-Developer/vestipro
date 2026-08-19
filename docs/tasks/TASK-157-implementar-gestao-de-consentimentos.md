# TASK-157 — Implementar gestão de consentimentos

**Epic:** EPIC-20 — LGPD e Privacidade
**Status:** ⬜ Pendente
**Depende de:** TASK-156 (política de privacidade e termos, base do modelo de aceite versionado)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o registro de consentimentos específicos (distintos do aceite geral de termos), como uso
de localização e comunicação de marketing, com uma tela onde o usuário pode revisar e revogar cada
consentimento a qualquer momento.

## Escopo técnico

- Modelar `ConsentRecord` por finalidade específica (ex.: uso de localização para roteirização/
  check-in — EPIC-24, comunicação de marketing/novidades), distinto do `UserPolicyAcceptance` geral
  (TASK-156).
- Tela "Privacidade e Consentimentos" onde o usuário revisa o que consentiu e pode revogar
  consentimentos opcionais a qualquer momento.
- Casos de uso: `GrantConsent`, `RevokeConsent`, `ListUserConsents`.
- Funcionalidades que dependem de consentimento específico (ex.: geolocalização) devem checar o
  consentimento vigente antes de ativar a funcionalidade, e reagir (desativar) quando revogado.

## Regras de negócio e restrições

- Consentimento é sempre opt-in explícito por finalidade; nunca pré-marcado como aceito.
- Revogar um consentimento não pode ser mais difícil que concedê-lo (mesmo número de passos e
  visibilidade).
- Revogação tem efeito imediato: a funcionalidade dependente é desativada assim que o consentimento é
  revogado, não apenas no próximo login.
- Consentimentos obrigatórios para o funcionamento básico do serviço (quando existirem) não podem
  ser confundidos com os opcionais/de marketing na tela de revisão.

## Testes obrigatórios

- Teste de caso de uso: conceder e revogar consentimento, com registro de data/hora e finalidade.
- Teste garantindo que funcionalidade dependente (ex.: coleta de localização) não ativa sem
  consentimento concedido.
- Teste garantindo que a revogação desativa a funcionalidade imediatamente, não apenas após novo
  login.
- Teste de widget da tela de revisão/revogação (lista clara de finalidades e estado atual).
- Teste de isolamento multi-tenant/usuário dos registros de consentimento.

## Critérios de aceite

- Usuário revisa, concede e revoga cada consentimento individualmente, com a mesma facilidade em
  ambas as direções.
- Funcionalidades sensíveis (ex.: localização) respeitam o consentimento vigente em tempo real.
- Todo consentimento e revogação fica registrado com finalidade, data e hora.
- Nenhum consentimento é assumido por padrão sem ação explícita do usuário.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
