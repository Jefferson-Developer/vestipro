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
8. Se algo impedir conclusao por bloqueio real (acesso a infraestrutura/producao, credenciais ou
   dispositivos que o ambiente nao tem, decisao que so um humano pode tomar):
   - Nao marque a task, nao crie `-CONCLUIDA.md`, nao invente hash.
   - Mova a task para o backlog: crie `docs/backlog/BACKLOG-XXX-titulo.md` (proximo numero livre)
     explicando o motivo real e quem precisa agir; liste em `docs/backlog/README.md`.
   - Em `docs/tasks/TASKS.md`, troque a linha `[ ] [TASK-XXX ...]` por uma linha sem checkbox
     apontando para o BACKLOG-XXX criado (ela sai da fila obrigatoria), e ajuste o total de tasks e a
     linha `Progresso: N / M` (M diminui em 1).
   - No arquivo original da task, adicione uma nota no topo apontando para o BACKLOG-XXX.
   - Faca commit dessa democao (`chore(backlog): move TASK-XXX para backlog - <motivo curto>`) e so
     faca push se ja autorizado.
   - Informe o motivo real ao usuario.
   - Se o bloqueio for outro (bug de implementacao, teste falhando por erro de codigo, ambiguidade
     que um replanejamento resolveria), NAO mova para o backlog — pare e reporte, backlog e so para
     bloqueio real de acesso/infra.
