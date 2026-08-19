# AGENTS.md — Protocolo obrigatório de execução do backlog

Este arquivo é lido automaticamente por agentes de IA (Codex CLI e Claude Code) antes de trabalhar
neste repositório. Ele define como qualquer agente deve executar o backlog técnico da plataforma de
força de vendas de moda B2B descrita em [`tasks.md`](tasks.md) (Master Specification).

**Não pule este arquivo.** As regras abaixo têm prioridade sobre qualquer atalho que pareça mais
rápido no momento.

O VestiPro tem como objetivo ser **o sistema de força de vendas mobile mais completo do mercado de
moda**: CRM, catálogo, pedidos, offline-first real, inteligência comercial, BI e relatórios de nível
internacional. Nenhuma task deve ser tratada como "só mais uma tela" — cada uma sustenta essa visão.

## Comando de retomada

Quando o usuário disser algo como:

```
/proxima-task
```
ou
```
Rode a próxima task
Continua o backlog
Próxima task do VestiPro
```

o agente deve:

1. Abrir `docs/tasks/TASKS.md`.
2. Encontrar o **primeiro checkbox `[ ]` não marcado** da lista — essa é a task atual. A ordem do
   arquivo é a ordem de execução (respeita dependências entre EPICs); não pule tasks e não escolha
   "a mais fácil".
3. Abrir o arquivo `docs/tasks/TASK-XXX-nome-da-task.md` correspondente.
4. Executar o fluxo obrigatório completo descrito abaixo, do início ao fim, para essa task.
5. Se a task já tiver sido concluída anteriormente por engano de checkbox (ex.: código já existe),
   verificar antes de assumir — nunca confiar cegamente no checkbox sem checar o estado real do
   repositório (`git log` quando houver repositório Git, arquivos existentes).

Se nenhum checkbox estiver desmarcado, informe que o backlog está 100% concluído e pergunte o que
fazer a seguir (ex.: iniciar tasks de evolução além do backlog atual).

## Uso obrigatório dos agentes especializados

Este projeto tem subagentes especializados registrados em `.claude/agents/`:

- **`flutter-senior-architect`** — arquitetura, domain, data, repositórios, casos de uso, BLoC,
  Firebase (Auth/Firestore/Storage/Functions/Analytics/Crashlytics/Performance/App Check/Remote
  Config/Cloud Messaging), multi-tenancy, RBAC, offline-first (banco local, Outbox, motor de
  sincronização, resolução de conflitos), motor de precificação, engine de insights, agregações de
  BI, segurança, testes, CI/CD, refatoração, performance, integrações e regras de negócio.
- **`flutter-ui-design-specialist`** — interface, Design System, componentes, páginas,
  responsividade, acessibilidade, UX, estados visuais, formulários, grades de tamanho/cor, tabelas,
  dashboards, gráficos, feedbacks, mobile/tablet/desktop/Flutter Web, experiência premium de moda.

Cada arquivo `docs/tasks/TASK-XXX-*.md` indica, na seção "Agentes obrigatórios", quais dos dois (ou
ambos) essa task exige. **Nenhuma implementação de código deve ser feita fora desses agentes**: o
agente principal (Claude Code ou Codex) deve delegar a implementação de fato a eles — via subagente
no Claude Code, ou seguindo à risca a persona/regras do arquivo correspondente quando a ferramenta em
uso não suportar subagentes nativos (ex.: Codex CLI deve ler o conteúdo de
`.claude/agents/flutter-senior-architect.md` e/ou `.claude/agents/flutter-ui-design-specialist.md` e
segui-lo como se fosse seu próprio system prompt para aquela parte do trabalho).

Tasks que envolvem tela **e** regra de negócio ao mesmo tempo (cadastro, dashboard, pedido, grade
comercial, catálogo, CRM, campanhas, usuários) usam os dois agentes.

## Fluxo obrigatório por task

### 1. Antes de desenvolver

- Ler a task completa em `docs/tasks/TASK-XXX-*.md`.
- Ler a seção correspondente da especificação funcional em `tasks.md` (Master Specification).
- Ler o(s) agente(s) obrigatório(s) da task.
- Identificar arquivos relacionados já existentes no repositório.
- Verificar se já existe implementação equivalente (não duplicar).
- Identificar dependências, riscos, regras de segurança, testes necessários.
- Identificar impactos em Analytics, Crashlytics, Firestore Rules, Storage Rules, Cloud Functions,
  offline/sincronização e multi-tenancy.
- Escrever um plano curto antes de tocar em código.

### 2. Durante o desenvolvimento

- Respeitar a arquitetura Clean/feature-first + BLoC definida pelo `flutter-senior-architect`.
- Nunca colocar regra de negócio na UI nem acessar Firestore/Storage diretamente em widgets.
- Nunca confiar apenas no `organizationId` enviado pelo cliente como fonte de autorização.
- Não duplicar código nem criar componentes/dependências redundantes.
- Não remover comportamento existente sem justificativa registrada.
- Não alterar arquivos fora do escopo da task.
- Não enfraquecer regras de segurança, não inserir segredos, não usar `print`, não deixar código
  morto/comentado, não deixar `TODO` sem contexto.
- Não quebrar suporte offline nem isolamento multi-tenant existente.
- Criar testes junto com a implementação.
- Preservar compatibilidade Android, iOS e Web.

### 3. Antes de concluir

Rodar sempre:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Quando aplicável à task:

```bash
flutter test integration_test
firebase emulators:exec "flutter test integration_test"
flutter build web
flutter build appbundle
flutter build ipa
```

Validar também (quando fizer sentido para a task): responsividade, acessibilidade, loading, empty
state, error state, permissões/RBAC, Analytics, Crashlytics, regras Firebase, comportamento offline,
paginação, performance, concorrência, rollback.

### 4. Documentação obrigatória

Ao concluir, criar `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md` com:

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

### 5. Commit e push (toda task termina assim, quando houver repositório Git configurado)

Este repositório pode não ter Git inicializado em algum momento do trabalho. Se `git status` falhar
por "not a git repository", informe isso ao usuário e pergunte se deve inicializar o repositório
antes de prosseguir — nunca inicialize um repositório Git ou crie o primeiro commit sem confirmação
explícita nesta conversa.

Quando houver repositório Git disponível:

```bash
git status
git diff
git add <arquivos relacionados à task — nunca "git add -A" às cegas>
git commit -m "tipo(modulo): descrição da implementação"
git push origin <branch> # somente quando autorizado explicitamente nesta conversa
```

Padrão de commit:

```text
<tipo>(<modulo>): <descricao curta>
```

Exemplos:

```text
feat(products): add configurable size grids
feat(orders): add offline order creation
fix(sync): resolve duplicated outbox items
refactor(crm): isolate opportunity use cases
test(pricing): cover discount policy edge cases
docs(tasks): document TASK-073 completion
```

Depois do commit, **marcar o checkbox da task em `docs/tasks/TASKS.md`** (`[ ]` → `[x]`) no mesmo
commit, e atualizar a linha "Progresso: N / 206" no rodapé desse arquivo.

Nunca:

- Criar commit sem testes.
- Fazer push de código quebrado.
- Fazer commit com segredo, arquivo temporário ou código gerado incorretamente.
- Fazer push direto em branch protegida de algo que quebra o analyzer/testes.
- Usar `--force` ou reescrever histórico remoto sem autorização explícita do usuário nesta conversa.
- Marcar checkbox como concluído sem commit correspondente (ou sem justificativa clara de por que o
  commit não foi possível).

Se o commit ou o push não puder ser feito (analyzer com erro, teste falhando, sem permissão, sem
Git, etc.):

1. Informar isso claramente ao usuário.
2. Explicar o motivo real.
3. Não afirmar que a task foi concluída.
4. Deixar os comandos exatos pendentes.
5. Não inventar hash de commit nem marcar o checkbox.

## Template de resposta final ao terminar uma task

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

## Onde encontrar cada coisa

- Especificação funcional completa e visão de produto: [`tasks.md`](tasks.md)
- Backlog e status: [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md)
- Tasks individuais: `docs/tasks/TASK-XXX-nome-da-task.md`
- Evidência de conclusão: `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md`
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md`
- Comando de retomada: `.claude/commands/proxima-task.md`
