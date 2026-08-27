---
description: Executa a proxima task pendente do backlog com modo economico de agentes, documentacao, commit e push quando autorizado, sem exigir testes no final por padrao.
---

Leia `AGENTS.md` e siga o modo economico:

1. Abra `docs/tasks/TASKS.md` e encontre o primeiro checkbox `[ ]` nao marcado.
2. Abra somente o arquivo `docs/tasks/TASK-XXX-*.md` correspondente.
3. Confirme se a task ja nao foi implementada.
4. Leia a secao relevante de `tasks.md`, nao o arquivo inteiro se nao for necessario.
5. Leia apenas os agentes aplicaveis:
   - tecnicos indicados na task: `flutter-senior-architect` e/ou `flutter-ui-design-specialist`;
   - negocio quando o escopo pedir: `vestipro-sales-representative-specialist` e/ou
     `vestipro-commercial-ops-strategist`.
6. Planeje curto, implemente, documente a conclusao, faca commit e so faca push com autorizacao
   explicita.
7. Nao trate criacao de testes, `flutter analyze` ou `flutter test` como etapa obrigatoria de
   encerramento. So execute essa parte se a task pedir explicitamente, se o usuario pedir ou se
   houver risco tecnico real que justifique a validacao.
8. Se algo impedir conclusao, informe o motivo real, nao marque a task e nao invente hash.
