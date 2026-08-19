# TASK-183 — Implementar integração WhatsApp Business

**Epic:** EPIC-26 — Comunicação Avançada
**Status:** ⬜ Pendente
**Depende de:** TASK-081 (compartilhamento de catálogo, fonte do link/seleção a ser enviado por WhatsApp), TASK-151 (central de notificações internas, passa a oferecer WhatsApp como canal adicional)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o vendedor envie catálogo, link de seleção (TASK-081) e notificações comerciais ao cliente via WhatsApp Business Cloud API (Meta), sempre com opt-in explícito do cliente e usando templates de mensagem previamente aprovados — nunca texto livre disparado em massa sem consentimento.

## Escopo técnico

- Cloud Function `sendWhatsAppMessage` que encapsula a chamada à WhatsApp Business Cloud API; token e phone number id ficam em secret manager/config de Functions, nunca no cliente Flutter.
- Modelar `WhatsAppOptIn` por cliente (status: solicitado, aceito, recusado, revogado; canal de coleta do consentimento; timestamp), com revogação bloqueando envios imediatamente.
- Cadastro de templates de mensagem pré-aprovados pela Meta (nome, idioma, variáveis); vendedor escolhe template e preenche variáveis — nunca texto livre fora da janela de 24h de sessão permitida pela própria política do WhatsApp.
- Reutilizar `CatalogShare` (TASK-081) como payload do template de envio de catálogo/link de seleção.
- Integrar com a central de notificações (TASK-151): notificações de pedido/status passam a oferecer WhatsApp como canal quando o opt-in do cliente estiver ativo.
- Webhook `handleWhatsAppStatus` processando status de entrega (enviado, entregue, lido, falhou) e refletindo no histórico de comunicação do cliente.
- Ação "Enviar por WhatsApp" no catálogo/pedido: exige opt-in ativo; caso ausente, direciona para o fluxo de solicitação de consentimento antes de qualquer envio.

## Regras de negócio e restrições

- Nenhum envio ocorre sem opt-in explícito e registrado; revogação bloqueia novos envios de forma imediata.
- Fora da janela de 24h, apenas templates aprovados podem ser usados — a Cloud Function valida isso antes de enviar, nunca confia no cliente para essa decisão.
- Credenciais da WhatsApp Business API nunca ficam acessíveis ao app Flutter, em nenhuma plataforma.
- Falha de envio é exibida ao vendedor com motivo compreensível (não "erro genérico"), permitindo reenvio manual.
- Envio via WhatsApp é canal complementar de comunicação comercial; nunca substitui obrigações legais atendidas por outros canais.

## Testes obrigatórios

- Testes da Cloud Function com mocks da API da Meta: sucesso, template inválido, opt-in ausente/revogado, token expirado, rate limit.
- Testes das transições de estado do opt-in, incluindo bloqueio imediato de envio após revogação.
- Testes do webhook de status: atualização correta do histórico por mensagem, eventos fora de ordem.
- Testes de widget: fluxo de solicitação de opt-in, seleção de template, envio com sucesso/erro, estados de entrega no histórico do cliente.

## Critérios de aceite

- Vendedor só consegue enviar mensagem WhatsApp para cliente com opt-in ativo.
- Envio usa template aprovado e reflete o status de entrega real no histórico do cliente.
- Revogação de opt-in é imediata e auditável.
- Nenhuma credencial de WhatsApp Business fica exposta no cliente Flutter.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
