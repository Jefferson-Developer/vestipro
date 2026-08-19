---
description: Executa a próxima task pendente do backlog em docs/tasks/TASKS.md, do início ao fim (agentes, testes, documentação, commit e push).
---

Leia `AGENTS.md` na raiz do projeto — ele contém o protocolo obrigatório completo. Depois:

1. Abra `docs/tasks/TASKS.md` e encontre o primeiro checkbox `[ ]` não marcado, na ordem em que
   aparecem. Essa é a task atual. Não pule tasks.
2. Confirme rapidamente no repositório (arquivos existentes, `git log` quando houver Git) que essa
   task realmente ainda não foi feita — não confie cegamente no checkbox se algo parecer suspeito.
3. Abra o arquivo `docs/tasks/TASK-XXX-nome-da-task.md` correspondente e execute o fluxo completo
   descrito em `AGENTS.md`: leitura prévia obrigatória (incluindo a seção relevante de `tasks.md`),
   uso dos agentes indicados na task (`flutter-senior-architect` e/ou
   `flutter-ui-design-specialist`), implementação, testes, `dart format` / `flutter analyze` /
   `flutter test` (e o que mais for aplicável), criação de
   `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md`, commit (e push quando houver Git configurado e
   autorização explícita), e marcação do checkbox correspondente (mais a linha de progresso) em
   `docs/tasks/TASKS.md`.
4. Se não conseguir concluir algo (analyzer falhando, teste quebrado, sem Git, push impossível),
   siga a seção "Se o commit ou o push não puder ser feito" de `AGENTS.md`: informe claramente, não
   marque a task como concluída e não invente hash de commit.
5. Ao final, responda usando o "Template de resposta final ao terminar uma task" de `AGENTS.md`.

Se todos os checkboxes de `docs/tasks/TASKS.md` já estiverem marcados, informe que o backlog atual
está concluído e pergunte se deve iniciar as tasks de evolução além do escopo atual (ver seção
"Tasks adicionais recomendadas" em `tasks.md`, já incorporadas como EPICs 22–31 se ainda não
estiverem no backlog).
