# Cloud Functions — VestiPro

Codebase de Cloud Functions for Firebase do VestiPro (TypeScript). Hospeda toda regra crítica que o
app não pode decidir sozinho: autorização fina, cálculo definitivo de preço, geração de número de
pedido, aprovações e regras financeiras (ver `AGENTS.md` e `tasks.md`, seção 4.2).

## Estrutura

```text
functions/
├── src/
│   ├── index.ts       # inicializa firebase-admin e agrega os exports públicos
│   ├── health/         # healthCheck — valida o pipeline de ponta a ponta (TASK-015)
│   ├── auth/            # reservado — RBAC/vínculo usuário-organização (TASK-029)
│   ├── pricing/         # reservado — motor de precificação server-side (TASK-088)
│   ├── orders/          # reservado — número de pedido, submissão, aprovações (TASK-101)
│   ├── insights/        # reservado — engine de insights comerciais (TASK-121)
│   └── admin/           # reservado — auditoria/alterações administrativas (TASK-033)
└── test/                # Jest — um arquivo de teste por função
```

Cada pasta de domínio reservada existe vazia de propósito (só um `index.ts` com `export {}` e um
comentário apontando a task que a populará) — nenhuma delas é importada por `src/index.ts` até ter
uma função real para exportar.

## Scripts

```bash
npm install        # instala dependências (dependencies + devDependencies)
npm run build      # compila src/ (TypeScript) -> lib/ (JavaScript), com tsc --strict
npm run lint       # ESLint (typescript-eslint) sobre src/ e test/
npm test           # Jest (ts-jest) sobre test/**/*.test.ts
npm run serve      # build + sobe só o emulador de Functions
npm run shell      # build + firebase functions:shell (chamada manual interativa)
npm run deploy     # firebase deploy --only functions (roda lint+build antes, via predeploy)
npm run logs       # firebase functions:log
```

`firebase deploy --only functions` (configurado em `firebase.json`, bloco `functions[0].predeploy`)
já executa `lint` e `build` automaticamente antes do deploy — nunca faz deploy de `src/` sem passar
por eles.

## Pipeline de deploy por ambiente

O VestiPro tem **um único projeto Firebase real, `vestipro`**, tratado como produção — decisão
registrada em [`../docs/adr/0002-topologia-firebase.md`](../docs/adr/0002-topologia-firebase.md).
Isso define o pipeline de Functions:

- **`development` e `staging`**: nunca fazem deploy real. Todo desenvolvimento e todo teste de
  função passam pelo Firebase Emulator Suite local (`firebase emulators:start --only functions` ou
  `firebase emulators:exec "..."`), que roda o código compilado em `lib/` sem tocar no projeto
  `vestipro` real. Não existe projeto/alias `vestipro-dev` ou `vestipro-staging` para apontar.
- **`production`**: é o único ambiente que efetivamente recebe `firebase deploy --only functions`,
  sempre contra o projeto `vestipro` (alias `default` em `.firebaserc`, na raiz do repositório).
  Antes de qualquer deploy real, validar a função no Emulator Suite — não há projeto de staging para
  ensaiar (mesma ressalva já registrada na ADR-0002).

Para apontar explicitamente o CLI para o projeto certo (equivalente a `firebase use <alias>`, hoje
com um único alias possível):

```bash
firebase use vestipro   # equivalente a firebase use default; não há outro projeto para trocar
firebase deploy --only functions
```

Se um dia um segundo projeto Firebase real for criado para `staging` (mudança de decisão da
ADR-0002), acrescente o alias correspondente em `.firebaserc` e um passo de `firebase use <alias>`
antes do deploy daquele ambiente — o restante do pipeline (`predeploy` de lint/build) não muda.

## Emulator Suite

```bash
firebase emulators:start --only functions,firestore,auth
```

Porta do emulador de Functions: `5001` (ver `firebase.json` e `lib/core/environment/` no app
Flutter, que resolve host/porta para todo SDK client-side, incluindo `cloud_functions`). O app
Flutter conecta a esse emulador automaticamente para os flavors `dev`/`staging`, via
`configureFunctions` (`lib/core/functions/configure_functions.dart`) — nunca em `prod`.

## Testes

`npm test` roda os testes Jest de `test/` usando `firebase-functions-test` (modo "online", sem
credenciais reais — as funções atuais não chamam nenhum serviço do Firebase Admin). Cada função nova
deve ganhar um arquivo `test/<nome-da-funcao>.test.ts` cobrindo pelo menos o caminho de sucesso e um
caminho de erro relevante (ex.: `HttpsError` esperado).
