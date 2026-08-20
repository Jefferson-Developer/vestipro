# AGENTS.md — Protocolo VestiPro

Instruções obrigatórias para executar o backlog técnico do VestiPro, plataforma mobile/Web de força
de vendas B2B de moda.

## Modo Econômico De Tokens

- Leia primeiro este arquivo, `docs/tasks/TASKS.md` e a task atual.
- Leia somente os agentes aplicáveis ao escopo da task.
- Não leia todos os agentes por padrão.
- Use `tasks.md` como referência sob demanda: abra apenas a seção relacionada à task.
- Se uma regra já estiver neste arquivo, não recarregue o mesmo conteúdo em outro lugar.
- Para tasks simples, use agentes como checklist; aprofunde apenas quando houver risco técnico,
  comercial, segurança, offline, multi-tenant, Firebase, UI complexa ou BI.

## Comando De Retomada

Quando o usuário disser `/proxima-task`, "próxima task", "roda a próxima task" ou equivalente:

1. Abra `docs/tasks/TASKS.md`.
2. Encontre o primeiro checkbox `[ ]` não marcado, na ordem do arquivo.
3. Abra `docs/tasks/TASK-XXX-nome-da-task.md`.
4. Verifique se já existe implementação equivalente antes de codar.
5. Leia a seção relevante de `tasks.md`.
6. Leia apenas os agentes exigidos/aplicáveis.
7. Planeje curto, implemente, teste, documente, commit e push somente quando autorizado.

Se não houver checkbox pendente, informe que o backlog atual está 100% concluído.

## Agentes

Agentes técnicos listados nas tasks:

- `flutter-senior-architect`: arquitetura, domain/data, BLoC, Firebase, RBAC, offline-first, sync,
  pricing, insights, BI, segurança, testes, CI/CD, integrações e performance.
- `flutter-ui-design-specialist`: UI Flutter, Design System, UX, responsividade, acessibilidade,
  formulários, grades, dashboards, gráficos, feedback visual e experiência premium de moda.

Agentes de negócio por escopo:

- `vestipro-sales-representative-specialist`: use quando a task afetar rotina do representante:
  carteira, CRM, lead, funil, visita, follow-up, catálogo, grade, pedido, orçamento, insights,
  metas individuais, WhatsApp, pós-venda ou venda offline.
- `vestipro-commercial-ops-strategist`: use quando a task afetar gestão: metas, ranking, comissão,
  política comercial, campanha, aprovação, forecast, dashboard, relatório, BI, margem, estoque,
  carteira, governança ou performance do time.

Regra: implementação de código fica nos agentes técnicos. Agentes de negócio orientam requisitos,
fluxo, métricas, riscos e critérios de aceite.

## Antes De Codar

- Leia a task inteira.
- Leia a seção funcional relevante em `tasks.md`.
- Leia agentes aplicáveis.
- Identifique arquivos existentes e implementação equivalente.
- Liste dependências, riscos, permissões, testes e impactos.
- Considere Analytics, Crashlytics, Firestore Rules, Storage Rules, Cloud Functions, offline/sync,
  multi-tenancy, performance e compatibilidade Android/iOS/Web.
- Escreva um plano curto antes de editar.

## Regras De Implementação

- Arquitetura Clean/feature-first + BLoC.
- UI não acessa Firestore/Storage/Drift diretamente.
- Regra de negócio não fica em widget.
- Nunca confiar apenas em `organizationId` vindo do cliente como autorização.
- RBAC em UI e backend.
- Não enfraquecer segurança, rules, isolamento tenant ou offline.
- Não duplicar componente, service, repository ou regra.
- Não remover comportamento existente sem justificativa.
- Não alterar arquivos fora do escopo.
- Não inserir segredo, `print`, código morto/comentado ou `TODO` sem contexto.
- Preservar Android, iOS e Web.

## Testes E Validação

Sempre que houver código Dart/Flutter, rode:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Quando aplicável:

```bash
flutter test integration_test
firebase emulators:exec "flutter test integration_test"
flutter build web
flutter build appbundle
flutter build ipa
```

Valide, quando fizer sentido: loading, empty, error, offline, sync, conflito, RBAC, Analytics,
Crashlytics, Firebase Rules, paginação, performance, concorrência, acessibilidade e responsividade.

Nunca afirme que executou teste/validação sem executar.

## Documentação De Conclusão

Ao concluir uma task, crie `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md` com:

```text
# TASK-XXX — Concluída (AAAA-MM-DD)

## Resumo
## Agentes utilizados
## Arquivos criados
## Arquivos alterados
## Arquitetura utilizada
## Regras de negócio implementadas
## Regras Firebase implementadas
## Analytics implementado
## Crashlytics implementado
## Impacto offline
## Impacto multi-tenant
## Testes criados
## Comandos executados
## Resultado do formatter
## Resultado do analyzer
## Resultado dos testes
## Decisões técnicas
## Riscos conhecidos
## Pendências
## Evidências
## Commit
## Push
## Hash do commit
## Branch
```

## Git, Commit E Push

Se `git status` falhar por "not a git repository", informe e pergunte antes de inicializar Git.

Quando houver Git:

```bash
git status
git diff
git add <arquivos da task>
git commit -m "tipo(modulo): descrição"
git push origin <branch>
```

Regras:

- Nunca use `git add -A` às cegas.
- Nunca faça push sem autorização explícita nesta conversa.
- Nunca use `--force` sem autorização explícita.
- Depois do commit, marque a task em `docs/tasks/TASKS.md` e atualize `Progresso: N / 206` no mesmo
  commit quando isso fizer parte da conclusão.
- Se commit/push/testes/analyzer falharem, informe o motivo real, não marque a task como concluída e
  não invente hash.

Padrão: `feat(products): add configurable size grids`, `fix(sync): resolve duplicated outbox items`,
`test(pricing): cover discount policy edge cases`, `docs(tasks): document TASK-073 completion`.

## Resposta Final De Task

Use o template abaixo:

```text
# TASK-XXX concluída

## Resumo
## Agentes utilizados
## Arquivos criados
## Arquivos alterados
## Regras implementadas
## Firebase
## Offline/Multi-tenant
## Analytics
## Crashlytics
## Testes criados
## Comandos executados
## Resultado do formatter
## Resultado do analyzer
## Resultado dos testes
## Documentação criada
## Commit
## Push
## Hash do commit
## Branch
## Riscos conhecidos
## Pendências
```

## Arquivos-Chave

- Especificação: `tasks.md`
- Backlog: `docs/tasks/TASKS.md`
- Tasks: `docs/tasks/TASK-XXX-nome-da-task.md`
- Conclusões: `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md`
- Agentes: `.claude/agents/`
- Comando: `.claude/commands/proxima-task.md`
