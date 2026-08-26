# BACKLOG-003 — Reverter Firestore Rules do "modo teste" para o `firestore.rules` real

**Status:** 🔴 Pendente — URGENTE (risco de segurança ativo em produção)
**Origem:** durante a investigação do bug "owner recebe 'sem permissão'" no login (26/08/2026), as
Firestore Security Rules do projeto real `vestipro` foram substituídas manualmente, via Firebase
Console, pelo template padrão de "modo teste" do Firebase.

## Contexto

As regras atualmente publicadas no projeto `vestipro` são:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2026, 9, 22);
    }
  }
}
```

Isso libera leitura e escrita de **toda** a base Firestore (todas as organizações, todos os clientes,
pedidos, membros etc.) para **qualquer pessoa com a URL/config do projeto — autenticada ou não** — até
22/09/2026. Não é uma restrição por tenant, por role ou por autenticação: é acesso total e irrestrito.

O `firestore.rules` versionado no repositório (multi-tenant, RBAC, TASK-030) permanece correto e já é
coberto pela suíte `firestore-tests/` (`@firebase/rules-unit-testing`), incluindo um teste que cobre
exatamente o cenário que motivou a troca (`collectionGroup("members")` filtrado pelo próprio `userId`,
usado por `MembershipRepository.listActiveByUser` — ver
`firestore-tests/firestore.rules.test.js:873-884`). A análise da regra "real" não encontrou motivo para
negar essa query para um membro consultando a própria Membership; a troca para o modo teste foi uma
tentativa de contornar um bloqueio cuja causa raiz ainda não foi confirmada (ver seção "Investigação em
aberto").

## Objetivo

1. Publicar de volta o `firestore.rules` do repositório (`firebase deploy --only firestore:rules`),
   fechando a brecha assim que possível.
2. Antes ou logo depois de reverter, confirmar (idealmente rodando `firestore-tests/` contra o Emulator
   Suite — precisa de Java instalado, ver BACKLOG-002) que o cenário de login do usuário
   `yBiszGHuDKgyYr3JeOZkosJ27wN2` (organização "Dino Vest",
   `8e84dcfa-fea3-4d5b-ab8b-75e9bbbbc6be`) realmente funciona com as regras reais — e não só porque o
   modo teste está mascarando um bug diferente (ex.: catálogo aparecendo "em preparação" mesmo com
   acesso liberado, o que sugere que o problema real pode estar em outro lugar, não nas Rules).

## Investigação em aberto

- O índice de collection group (`members.userId`, `COLLECTION_GROUP`) foi publicado e confirmado via
  `firebase firestore:indexes` (field override presente).
- As regras reais, lidas por hand-analysis e comparadas ao teste existente
  (`firestore.rules.test.js:873-884`), deveriam permitir a query `collectionGroup('members').where('userId',
  '==', <próprio uid>)` mesmo para quem não é OWNER — o teste espelha exatamente esse caso com `rep-a`.
- Não foi possível rodar `firestore-tests/` neste ambiente (falta Java no PATH; só o JBR do Android
  Studio foi encontrado, não testado como substituto).
- Mesmo com as regras em modo teste (tudo liberado), o catálogo apareceu como "em preparação" em vez de
  mostrar os 50 produtos de teste cadastrados na organização — o que sugere fortemente que o bloqueio
  real (ou pelo menos esse sintoma específico) **não é** (ou não é só) Security Rules, e sim algo na
  camada de sincronização/cache local (offline-first, Drift) ou na lógica de carregamento do catálogo.
  Precisa de investigação própria, separada desta.

## Arquivos prováveis

- `firestore.rules` (já correto no repo — só falta publicar de novo)
- `firestore-tests/firestore.rules.test.js` (já cobre o cenário)
- Área de carregamento do catálogo (`lib/features/catalog/`) — para a investigação do "em preparação"
