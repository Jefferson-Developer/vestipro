# TASK-181 — Concluída (2026-09-07)

## Resumo

Implementado o compartilhamento de um rascunho de pedido como snapshot público versionado. O
cliente revisa variantes e quantidades e, se a política da organização permitir, preços e total;
sem login, pode aprovar, comentar ou recusar itens. A resposta atualiza o compartilhamento e gera
notificação com deep link para o carrinho de origem, mas nunca cria ou submete um pedido.

## Agentes utilizados

- `flutter-senior-architect`: arquitetura, Functions, DI, segurança e testes.
- `flutter-ui-design-specialist`: sheet do vendedor e página pública responsiva.
- `vestipro-sales-representative-specialist`: snapshot, próxima ação e controle final do vendedor.

## Arquivos criados

- `functions/src/cart_shares/` e `functions/test/cart_shares/`.
- `lib/features/cart_share/` e `test/features/cart_share/`.

## Arquivos alterados

- Functions: `functions/src/index.ts`.
- Firebase: `firestore.rules`, `firestore.indexes.json`, `firestore-tests/firestore.rules.test.js`.
- Flutter: `lib/app/bootstrap.dart`, `lib/app/injection.config.dart`, navegação, analytics e
  `lib/features/orders/presentation/pages/order_draft_page.dart`.
- Testes/documentação: catálogo de analytics e `docs/tasks/TASKS.md`.

## Arquitetura utilizada

Feature-first + Clean Architecture: UI → `CartShareCubit` → use cases → `CartShareRepository` →
`CloudFunctionsService`. A rota pública `/cart-share/:token` resolve o tenant somente no servidor.

## Regras de negócio implementadas

- Token aleatório criado server-side; somente o SHA-256 é persistido.
- Snapshot carrega `sourceCartId`, `sourceCartVersion`, variantes, quantidades e valores.
- O sheet avisa que editar o carrinho exige gerar novo link para evitar revisão desatualizada.
- Preços aparecem somente se solicitados e `settings.allowCartSharePrices == true` no servidor.
- Sugestão de alteração exige comentário; itens recusados precisam pertencer ao snapshot.
- Revisão é apenas sinal: nenhuma escrita é feita em `orders`; o vendedor continua responsável pela
  submissão final e recebe notificação ligada ao rascunho de origem.

## Regras Firebase implementadas

- `cartShares`: leitura direta apenas pelo criador ou `catalog.manage`; escrita client-side sempre
  negada. Visitante usa exclusivamente Functions.
- Índice collection-group de `cartShares.tokenHash`.
- Membership ativa é revalidada; `organizationId` do payload nunca autoriza sozinho.

## Analytics implementado

- `cart_share_created` e `cart_share_reviewed`, sem comentário/PII.

## Crashlytics implementado

Sem captura específica nova; exceções externas viram `Failure` e estados recuperáveis, sem `print`.

## Impacto offline

O rascunho permanece offline-first. Criar, abrir e revisar link exige rede e não altera o cache local.

## Impacto multi-tenant

Dados ficam sob a organização revalidada. O preview omite IDs internos, criador e hash do token.

## Testes criados

- Validação de quantidade/subtotal, validade e ocultação de preços.
- Use cases de criação, carrinho vazio e comentário obrigatório.
- Widget público com quantidade, total, aprovação e analytics.
- Integração de revisão verificando notificação e ausência de pedido automático.
- Rules positivas/negativas, inclusive acesso anônimo e escrita forjada.

## Comandos executados

```text
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test test/features/cart_share test/core/analytics/analytics_events_test.dart test/core/navigation/app_router_test.dart test/core/navigation/session_auth_guard_test.dart test/features/orders/presentation/pages/order_draft_page_test.dart
npm --prefix functions run build
npm --prefix functions run lint
npm --prefix functions test -- --runInBand test/cart_shares/cart-share-shared.test.ts
firebase emulators:exec --only firestore "npm --prefix firestore-tests test -- --runInBand"
git diff --check
```

## Resultado do formatter

Arquivos da task formatados. Três arquivos fora do escopo apresentaram apenas drift de formatação e
não serão adicionados ao commit.

## Resultado do analyzer

Zero erros da task; 15 avisos `info` preexistentes e fora do escopo.

## Resultado dos testes

- Flutter focado/regressão: 36 testes passando.
- Jest unitário: 3 testes passando.
- TypeScript build, ESLint e `git diff --check`: sucesso.
- Emulator/Rules e teste integrado de revisão não executados: Java ausente (`spawn java ENOENT`).
  As suítes estão criadas para CI com Java.

## Decisões técnicas

- Snapshot imutável e versionado impede mudança silenciosa durante a revisão.
- A preferência de preço do vendedor nunca substitui a política server-side da organização.
- A notificação referencia o rascunho local; criar um pedido remoto apenas para refletir a revisão
  quebraria o fluxo offline e a submissão formal da TASK-101.

## Riscos conhecidos

- Functions/Rules dependentes do Emulator ainda precisam ser executadas em ambiente com Java.
- Links já emitidos não acompanham edições: o vendedor deve gerar um novo snapshot.

## Pendências

- Executar as suítes de Emulator em CI com Java antes do deploy.

## Evidências

- Flutter: `+36: All tests passed!`; Jest: `3 passed`; `tsc`/ESLint sem erros.

## Commit

Commit local único desta task.

## Push

Não realizado, conforme solicitado.

## Hash do commit

O `HEAD` desta task; hash informado na resposta final.

## Branch

`main`
