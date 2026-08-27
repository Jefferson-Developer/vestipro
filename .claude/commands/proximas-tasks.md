---
description: Executa N tasks pendentes do backlog em sequencia (usuario escolhe a quantidade), cada uma isolada em um subagente com contexto limpo, documentando e commitando ao final de cada task, sem exigir testes no final por padrao.
argument-hint: [quantidade de tasks]
---

Leia `AGENTS.md` e siga o modo economico. Este comando executa **varias** tasks pendentes em
sequencia, uma de cada vez, isolando cada task em um subagente proprio para manter o contexto limpo
entre uma task e outra.

1. Quantidade de tasks (N):
   - Se `$ARGUMENTS` contiver um numero, use-o como N.
   - Caso contrario, pergunte ao usuario quantas tasks ele quer rodar nesta rodada antes de comecar.
2. Autorizacao de push:
   - Se ainda nao houver autorizacao explicita de push nesta conversa, pergunte ao usuario se cada
     task deve terminar apenas com commit local ou tambem com `git push`.
   - Guarde essa decisao e repasse-a de forma explicita a cada subagente.
3. Repita ate completar N tasks concluidas, o backlog acabar ou uma task travar:
   a. Delegue a execucao de **uma unica task completa** a um novo subagente.
   b. No prompt do subagente, inclua o protocolo completo do `/proxima-task`:
      - abrir `docs/tasks/TASKS.md` e achar o primeiro checkbox `[ ]` nao marcado;
      - abrir somente o `docs/tasks/TASK-XXX-*.md` correspondente;
      - confirmar que a task ainda nao foi implementada;
      - ler apenas a secao relevante de `tasks.md`, nao o arquivo inteiro;
      - ler somente os agentes aplicaveis ao escopo;
      - planejar curto, implementar e documentar;
      - nao tratar criacao de testes, `flutter analyze` ou `flutter test` como etapa obrigatoria de
        encerramento; so executar quando a task pedir explicitamente, o usuario pedir ou houver
        risco tecnico real;
      - documentar a conclusao em `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md`;
      - marcar o checkbox e atualizar `Progresso` em `docs/tasks/TASKS.md` no mesmo commit;
      - fazer `git commit` e, **somente se autorizado no passo 2**, `git push`;
      - se algo impedir a conclusao, nao marcar a task, nao inventar hash e reportar o motivo real.
   c. Peca ao subagente um retorno curto e estruturado: numero/titulo da task, arquivos criados e
      alterados, validacoes executadas (se houver), hash do commit, se houve push, e
      pendencias/riscos.
   d. Rode os subagentes em **sequencia**, nunca em paralelo.
   e. Se `docs/tasks/TASKS.md` nao tiver mais checkbox pendente, pare o loop e informe ao usuario
      quantas tasks foram de fato concluidas nesta rodada.
   f. Se um subagente nao conseguir concluir a task por bloqueio real, dependencia faltando,
      documentacao/commit falhando ou outra razao realmente impeditiva, pare o loop nessa task e
      informe o motivo real ao usuario.
4. Ao final, apresente ao usuario um resumo consolidado da rodada: lista das tasks concluidas
   (numero, titulo, hash do commit, push sim/nao) e, se aplicavel, o status da task em que o loop
   parou.

Regras que continuam valendo em cada task, sem excecao: nunca usar `git add -A` as cegas, nunca
fazer push sem autorizacao explicita, nunca marcar uma task sem implementacao correspondente, nunca
inventar hash de commit, nunca alterar arquivos fora do escopo da task.
