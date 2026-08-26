# BACKLOG-002 — Rodar a suíte de testes de Firestore Rules em CI

**Status:** ⬜ Pendente
**Origem:** correção do bug "owner recebe 'sem permissão'" (nova regra `members.list` em
`firestore.rules`, TASK-030).

## Contexto

`firestore-tests/` contém testes positivos e negativos de `firestore.rules`
(`@firebase/rules-unit-testing` + Jest), incluindo os 3 testes novos cobrindo a regra `members.list` usada
por `MembershipRepository.listActiveByUser`. O comando oficial é:

```
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"
```

Isso exige Java instalado e no `PATH` (o emulador do Firestore roda em Java). Não existe pipeline de CI
neste repositório hoje (sem `.github/workflows` nem equivalente) — a suíte só roda manualmente, quando
alguém lembra de rodar.

## Objetivo

Automatizar essa suíte para rodar a cada mudança em `firestore.rules`/`firestore.indexes.json`, sem
depender de alguém lembrar de rodar localmente.

## Escopo provável

- Criar pipeline de CI (ex.: GitHub Actions) para o repositório, caso ainda não exista nenhum.
- Job dedicado com Java configurado, rodando
  `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` em toda mudança que
  toque `firestore.rules`, `firestore.indexes.json` ou `firestore-tests/**`.

## Arquivos prováveis

- `firestore-tests/` (testes já existentes)
- Novo workflow de CI (a definir onde este repositório hospeda sua automação).
