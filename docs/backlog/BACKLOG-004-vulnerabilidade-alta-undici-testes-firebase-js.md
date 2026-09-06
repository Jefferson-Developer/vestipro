# BACKLOG-004 — Vulnerabilidade alta (`undici`) nas dependências de teste do Firebase JS SDK

**Status:** ⬜ Pendente
**Origem:** TASK-165 (criação do pipeline de CI/CD), ao ligar `npm audit --audit-level=high` como
quality gate para `firestore-tests/` e `storage-tests/`.

## Contexto

`npm audit --audit-level=high` reporta **1 vulnerabilidade alta** em `firestore-tests/` e em
`storage-tests/`: `undici <=6.27.0`, empacotado transitivamente pelo pacote `firebase`
(`^10.14.1`, devDependency de `storage-tests/package.json`, usado para exercitar
`@firebase/rules-unit-testing` contra o Emulator) e por `@firebase/rules-unit-testing` em ambos os
projetos.

O fix automático (`npm audit fix`) não resolve porque exige um bump de major version do pacote
`firebase` (10.x → 11.x). `npm audit fix --force` aplicaria esse bump, mas é um upgrade de major
version de um SDK cujo comportamento nos testes de Rules **não pôde ser revalidado nesta sessão**
(o ambiente de execução não tem Java instalado, então os testes reais contra o Emulator Suite —
`firestore-tests`/`storage-tests` — não puderam rodar aqui; ver `docs/tasks/TASK-162-*-CONCLUIDA.md`
e `docs/tasks/TASK-165-criar-pipeline-ci-cd-CONCLUIDA.md`).

`functions/` também tem vulnerabilidades (14 moderadas, nenhuma alta/crítica), abaixo do limiar
`--audit-level=high` usado pelo pipeline; não bloqueia o gate hoje.

Nenhum destes pacotes é usado pelo app Flutter em produção nem pelo runtime das Cloud Functions
publicadas — são exclusivamente devDependencies de tooling de teste (`firestore-tests/`,
`storage-tests/`), mas ainda assim merecem correção.

## Objetivo

Atualizar `firebase`/`@firebase/rules-unit-testing` (e qualquer outra dependência que ainda
empacote `undici <=6.27.0`) para uma versão sem a vulnerabilidade em `firestore-tests/` e
`storage-tests/`, revalidando as duas suítes contra o Firebase Emulator Suite real (precisa de Java
instalado) antes de considerar a correção concluída.

## Escopo provável

- Bump de `firebase` (e dependências relacionadas) em `storage-tests/package.json` e
  `firestore-tests/package.json` para a versão mínima que resolve `undici`.
- Rodar `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` e
  `firebase emulators:exec --only firestore,storage "npm --prefix storage-tests test"` (ou
  `npm run test:integration` na raiz) em ambiente com Java, confirmando que nenhum teste quebrou
  com o SDK mais novo.
- Reavaliar `npm audit --audit-level=high` em `functions/` periodicamente (as 14 moderadas atuais
  não bloqueiam o pipeline, mas podem evoluir).

## Arquivos prováveis

- `firestore-tests/package.json`, `firestore-tests/package-lock.json`
- `storage-tests/package.json`, `storage-tests/package-lock.json`
- `.github/workflows/ci.yml` (job `dependency-audit`, TASK-165) — nenhuma mudança esperada aqui,
  apenas o gate passará a ficar verde depois da correção.
