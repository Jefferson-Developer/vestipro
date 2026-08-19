# TASK-173 — Implementar SSO corporativo (SAML/OIDC)

**Epic:** EPIC-23 — Identidade Corporativa e Internacionalização
**Status:** ⬜ Pendente
**Depende de:** TASK-012 (Configurar Firebase Authentication base — SSO estende a autenticação já configurada).

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Permitir que organizações clientes usem seu próprio provedor de identidade corporativo (Azure AD, Okta, Google Workspace etc.) para autenticar usuários do VestiPro via SAML 2.0 e/ou OIDC, com provisionamento automático de usuário no primeiro login (just-in-time), respeitando o RBAC já existente.

## Escopo técnico

- Configurar Firebase Authentication/Identity Platform para SSO baseado em SAML e/ou OIDC, permitindo múltiplos provedores de identidade, um por organização.
- Tela de configuração (portal admin) onde o gestor da organização cadastra os metadados do próprio IdP (metadata XML do SAML ou client id/issuer do OIDC) sem depender de deploy.
- Fluxo de login alternativo: usuário identifica a organização (ou domínio de e-mail) e é redirecionado ao IdP corporativo configurado para aquela organização.
- Provisionamento just-in-time: no primeiro login via SSO, criar automaticamente o membro da organização com um papel padrão configurável (nunca papel administrativo por padrão), reaproveitando o mesmo modelo de `members`/RBAC já usado pelo login tradicional.
- Mapear claims do IdP (nome, e-mail, eventualmente grupo/departamento) para os campos já existentes do usuário no VestiPro.
- Documentar o caminho equivalente de desativação no VestiPro quando o acesso é removido no IdP corporativo (mesmo que não totalmente automático nesta primeira versão).

## Regras de negócio e restrições

- SSO nunca provisiona usuário com papel administrativo/gestor por padrão — papel inicial é sempre o mais restritivo configurado pela organização.
- Usuário provisionado via SSO segue exatamente o mesmo RBAC e isolamento multi-tenant que qualquer outro usuário — não existe "usuário SSO" com regras de autorização diferentes.
- Configuração de um IdP pertence exclusivamente à organização que o cadastrou; nunca é compartilhada nem reaproveitada por outra organização.
- Login SSO mal configurado (metadata inválida, certificado expirado) falha de forma segura e informativa, nunca concede acesso por fallback silencioso.

## Testes obrigatórios

- Teste de fluxo de login SAML/OIDC usando IdP de teste/mock.
- Teste de provisionamento just-in-time: primeiro login cria membro com papel padrão correto.
- Teste de isolamento: configuração de IdP de uma organização não afeta nem autentica usuários de outra.
- Teste de falha de configuração (metadata inválida) resultando em erro seguro, sem acesso concedido.
- Teste de regras Firestore garantindo que o usuário provisionado via SSO respeita as mesmas regras de autorização dos demais.

## Critérios de aceite

- Usuário de uma organização cliente loga usando o IdP corporativo configurado, sendo provisionado automaticamente com papel padrão correto.
- Nenhuma organização consegue autenticar usuários usando a configuração de IdP de outra.
- RBAC existente continua sendo a única fonte de autorização, também para usuários SSO.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
