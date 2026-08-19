# TASK-049 — Implementar cadastro de cliente

**Epic:** EPIC-06 — Clientes
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer) — o formulário opera sobre a entidade, value objects e casos de uso já definidos; TASK-020 (Design System foundations) — o formulário deve usar exclusivamente tokens/componentes já definidos, nunca valores arbitrários.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela e o fluxo de cadastro/edição de cliente (pessoa jurídica e física), com campos obrigatórios configuráveis por organização, validação de documento em tempo real e capacidade de salvar rascunho incompleto, permitindo que o vendedor cadastre um cliente rapidamente em campo mesmo sem preencher tudo de uma vez.

## Escopo técnico

- Página `CustomerFormPage` (presentation) com seções: identificação, contato principal, classificação/potencial, vendedor responsável (quando permitido pelo RBAC).
- `CustomerFormBloc` com eventos por campo, `CustomerFormSubmitted` e `CustomerFormDraftSaved`.
- Alternância de campos conforme `CustomerType`: PJ exibe razão social/IE; PF exibe nome completo/CPF.
- Configuração por organização de campos obrigatórios adicionais (ex.: telefone obrigatório, email obrigatório), lida das configurações da organização (TASK-026/037/038).
- Validação de CNPJ/CPF client-side (feedback imediato), reaproveitando o value object `CnpjCpf` da TASK-048; a validação definitiva de duplicidade permanece no caso de uso/repositório.
- Persistência local de rascunho (Drift/cache local) permitindo retomar cadastro incompleto após fechar o app.
- Uso exclusivo de componentes de formulário do Design System (TASK-022) para inputs, labels persistentes e mensagens de erro.

## Regras de negócio e restrições

- Campos obrigatórios mínimos (documento, nome/razão social) nunca podem ser desabilitados pela configuração da organização — apenas campos adicionais são configuráveis.
- Bloquear envio duplicado (dois toques) durante a submissão.
- Nunca limpar dados do formulário após erro de validação ou falha de rede.
- RBAC: apenas perfis com permissão de criar cliente (`OWNER`, `ADMIN`, `SALES_MANAGER`, `SALES_REP` conforme política configurada) veem a ação de cadastro.
- Documento duplicado na organização deve bloquear a submissão com mensagem clara antes mesmo do envio ao backend, mas a validação definitiva de unicidade ocorre no repositório/backend.

## Testes obrigatórios

- Testes de widget: formulário PJ, formulário PF, alternância de tipo, presença/ausência de campos obrigatórios configuráveis.
- Testes de bloc: submissão válida, submissão com documento inválido, submissão com documento duplicado, salvar rascunho e retomar.
- Teste de acessibilidade: labels associadas aos campos, foco movido para o campo com erro.
- Teste de comportamento offline: cadastro salvo localmente quando sem conexão, marcado como pendente de sincronização.

## Critérios de aceite

- Cadastro funciona para PJ e PF com validação de documento e campos obrigatórios configuráveis por organização.
- Rascunho pode ser salvo e retomado sem perda de dados.
- RBAC aplicado na visibilidade da ação de cadastro.
- `flutter analyze`, `dart format` e testes passam; estados de loading, erro, vazio e offline tratados na tela.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
