---
description: Executa N tasks pendentes do backlog em sequência (usuário escolhe a quantidade), cada uma isolada em um subagente com contexto limpo, documentando e commitando ao final de cada task.
argument-hint: [quantidade de tasks]
---

Leia `AGENTS.md` e siga o modo econômico. Este comando executa **várias** tasks pendentes em
sequência, uma de cada vez, isolando cada task em um subagente próprio para manter o contexto limpo
entre uma task e outra (evita acumular no contexto principal os arquivos lidos pelas tasks
anteriores).

1. Quantidade de tasks (N):
   - Se `$ARGUMENTS` contiver um número, use-o como N.
   - Caso contrário, pergunte ao usuário quantas tasks ele quer rodar nesta rodada antes de começar.
2. Autorização de push:
   - Se ainda não houver autorização explícita de push nesta conversa, pergunte ao usuário se cada
     task deve terminar apenas com commit local ou também com `git push`.
   - Guarde essa decisão e repasse-a de forma explícita a cada subagente — subagentes não têm acesso
     ao histórico desta conversa, então a autorização precisa ir escrita no prompt de cada um.
3. Repita até completar N tasks concluídas, o backlog acabar ou uma task travar:
   a. Delegue a execução de **uma única task completa** a um novo subagente (Agent tool). Não
      reaproveite um subagente já usado em uma task anterior — cada task começa em um subagente
      novo, sem memória do que foi feito antes. Isso é o mecanismo de "limpar o contexto" entre
      tasks.
   b. No prompt do subagente, inclua o protocolo completo do `/proxima-task`:
      - abrir `docs/tasks/TASKS.md` e achar o primeiro checkbox `[ ]` não marcado;
      - abrir somente o `docs/tasks/TASK-XXX-*.md` correspondente;
      - confirmar que a task ainda não foi implementada;
      - ler apenas a seção relevante de `tasks.md`, não o arquivo inteiro;
      - ler somente os agentes aplicáveis ao escopo (técnicos e/ou de negócio, conforme `AGENTS.md`);
      - planejar curto, implementar, testar (`dart format`, `flutter analyze`, `flutter test` e o que
        mais se aplicar);
      - documentar a conclusão em `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md`;
      - marcar o checkbox e atualizar `Progresso: N / 206` em `docs/tasks/TASKS.md` no mesmo commit;
      - fazer `git commit` e, **somente se autorizado no passo 2**, `git push`;
      - se algo impedir a conclusão, não marcar a task, não inventar hash e reportar o motivo real.
   c. Peça ao subagente um retorno curto e estruturado: número/título da task, arquivos criados e
      alterados, resultado dos testes, hash do commit, se houve push, e pendências/riscos.
   d. Rode os subagentes em **sequência**, nunca em paralelo — cada task pode depender do estado que
      a anterior deixou em `docs/tasks/TASKS.md` e nos arquivos do projeto.
   e. Se `docs/tasks/TASKS.md` não tiver mais checkbox pendente, pare o loop e informe ao usuário
      quantas tasks foram de fato concluídas nesta rodada (pode ser menos que N).
   f. Se um subagente não conseguir concluir a task (bloqueio, dependência faltando, teste
      quebrando), pare o loop nessa task — não avance para a próxima — e informe o motivo real ao
      usuário.
4. Ao final (por atingir N, esgotar o backlog ou encontrar um bloqueio), apresente ao usuário um
   resumo consolidado da rodada: lista das tasks concluídas (número, título, hash do commit, push
   sim/não) e, se aplicável, o status da task em que o loop parou.

Regras que continuam valendo em cada task, sem exceção: nunca usar `git add -A` às cegas, nunca
fazer push sem autorização explícita, nunca marcar uma task sem implementação e testes
correspondentes, nunca inventar hash de commit, nunca alterar arquivos fora do escopo da task.
