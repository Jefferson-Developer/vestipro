# TASK-162 — Criar testes de integração com Firebase Emulator

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Status:** ⬜ Pendente
**Depende de:** TASK-015 (Cloud Functions for Firebase, alvo dos testes de integração), TASK-030
(Firestore Security Rules, alvo dos testes positivo/negativo)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Validar Cloud Functions e Firestore/Storage Security Rules end-to-end no Firebase Emulator Suite,
com pipeline automatizado (`firebase emulators:exec`), como segundo pilar do checklist de qualidade
que antecede o release do MVP (TASK-166).

## Escopo técnico

- Configurar/validar o Firebase Emulator Suite (Auth, Firestore, Functions, Storage) e o script
  `firebase emulators:exec` integrado à suíte de testes do projeto.
- Escrever testes de integração end-to-end contra o Emulator para as Cloud Functions críticas (motor
  de precificação server-side, geração de número de pedido, aprovações, agregações de BI).
- Escrever testes positivo e negativo de Firestore/Storage Security Rules para as entidades sensíveis
  do modelo de collections (`customers`, `orders`, `priceLists`, `auditLogs`, entre outras).
- Cobrir cenário multi-tenant: usuário da organização A nunca lê/escreve dado da organização B,
  validado diretamente contra as Rules no Emulator (não apenas mockado no código do app).
- Automatizar a execução via `firebase emulators:exec "flutter test integration_test"`, preparando o
  terreno para a integração com o CI/CD (TASK-165).

## Regras de negócio e restrições

- Toda Cloud Function que calcula preço, gera número de pedido ou aprova/rejeita deve ter teste de
  integração real contra o Emulator, não apenas teste unitário mockado.
- Toda entidade sensível listada no modelo de collections deve ter teste positivo (acesso permitido)
  e negativo (acesso negado) de Security Rules.
- Testes de integração nunca dependem de projeto Firebase real de produção/staging — sempre Emulator
  local.

## Testes obrigatórios

- Teste de integração da Cloud Function de precificação: preço correto, desconto acima do limite
  bloqueado ou gerando fluxo de aprovação.
- Teste de integração da geração de número de pedido: unicidade sob concorrência (duas submissões
  simultâneas).
- Teste positivo/negativo de Firestore Rules para `customers`, `orders`, `priceLists` e `auditLogs`.
- Teste multi-tenant negativo: usuário da organização A tentando ler/escrever dado da organização B é
  rejeitado pelas Rules.
- Teste automatizado via `firebase emulators:exec` rodando toda a suíte `integration_test` sem
  intervenção manual.

## Critérios de aceite

- `firebase emulators:exec "flutter test integration_test"` executa localmente com sucesso, cobrindo
  Functions e Rules críticas.
- Toda entidade sensível tem teste positivo e negativo de Security Rules.
- Isolamento multi-tenant é validado diretamente contra as Rules reais, não apenas por convenção de
  código.
- Pipeline de integração está pronto para ser plugado no CI/CD (TASK-165).

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
