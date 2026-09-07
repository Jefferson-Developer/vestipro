# TASK-182 — Concluída (2026-09-07)

## Resumo

Portal B2B autenticado do comprador, isolado por organização e `customerId`, com catálogo
white-label, histórico/status e repetição revalidada contra preço e estoque atuais. O acesso nasce
de convite interno e pedidos usam o pipeline server-side existente, sempre sob revisão comercial.

## Agentes utilizados

- `flutter-senior-architect`: arquitetura, RBAC, Functions, Rules e pedidos.
- `flutter-ui-design-specialist`: UI responsiva e estados.
- `vestipro-sales-representative-specialist`: repetição rápida e aprovação.

## Arquivos criados

- `functions/src/customer_portal/`, `functions/test/customer_portal/`.
- `lib/features/customer_portal/`, `test/features/customer_portal/`.

## Arquivos alterados

- `functions/src/index.ts`, `functions/src/orders/submit-order.ts` e seu teste.
- `firestore.rules`, `firestore-tests/firestore.rules.test.js`.
- `lib/app/bootstrap.dart`, `lib/app/injection.config.dart` e navegação central.
- `docs/tasks/TASKS.md`.

## Arquitetura utilizada

Feature-first + Clean Architecture: página → Cubit → use cases → repository → Cloud Functions.
Autorização, vínculo, reprecificação, estoque e aprovação permanecem no servidor.

## Regras de negócio implementadas

- `CUSTOMER_PORTAL` é vinculado obrigatoriamente a um `customerId`.
- OWNER/ADMIN/SALES_MANAGER/SALES_REP convidam; vendedor somente para sua carteira.
- Token criptográfico, apenas SHA-256 persistido, validade de sete dias e e-mail destinatário.
- Repetição relê tabela de preços e saldos, limita quantidade e elimina indisponíveis.
- Submissão ignora vendedor enviado pelo comprador, deriva o representante primário, executa o
  pipeline TASK-101 e inicia em `under_review`.

## Regras Firebase implementadas

Cliente externo lê apenas seu Customer e Orders. Outro cliente/tenant e escrita direta são negados;
mutações usam Functions e Membership real.

## Analytics implementado

Nenhum evento novo; nenhuma PII adicional.

## Crashlytics implementado

Sem captura específica; falhas viram estado recuperável no Cubit.

## Impacto offline

Portal exige rede para garantir preço, estoque e rastreio atuais; o offline interno não foi alterado.

## Impacto multi-tenant

Isolamento por `organizationId + customerId`, derivado da Membership, nunca do payload.

## Testes criados

- Provisionamento/token/expiração.
- Repetição com preço alterado e estoque reduzido/zerado.
- Submissão no pipeline existente, vendedor derivado e revisão obrigatória.
- Widget mobile/Web com marca, catálogo, histórico e repetição.
- Rules positivas/negativas para próprio cliente, outro cliente/tenant e escrita forjada.

## Comandos executados

```text
npm --prefix functions run build
npm --prefix functions run lint -- --quiet
npm --prefix functions test -- --runInBand test/customer_portal/customer-portal-shared.test.ts
dart run build_runner build --delete-conflicting-outputs
dart format <arquivos da task>
flutter analyze lib/features/customer_portal lib/core/navigation/app_router.dart lib/core/navigation/app_route_paths.dart lib/app/bootstrap.dart test/features/customer_portal
flutter test test/features/customer_portal/customer_portal_test.dart
firebase emulators:exec --only firestore "npm --prefix firestore-tests test -- --runInBand"
```

## Resultado do formatter

Arquivos Dart da task formatados; os três arquivos dirty fora do escopo foram preservados.

## Resultado do analyzer

Sem issues nos arquivos analisados da task.

## Resultado dos testes

- TypeScript/ESLint: sucesso; Jest: 2 testes passando; Flutter: 2 testes passando.
- Firestore Emulator não executado: Java ausente (`spawn java ENOENT`). O teste foi criado para CI.

## Decisões técnicas

- Snapshot do portal vem de Function segura, além das Rules.
- Pedido do portal sempre exige revisão básica; multinível pertence ao EPIC-29.
- Repetição produz carrinho revalidado, sem copiar valores históricos.

## Riscos conhecidos

- Executar Rules no Emulator com Java antes do deploy.
- Catálogo/histórico limitados aos 50 registros mais recentes; paginação pode evoluir.

## Pendências

- Executar a suíte Firestore Rules em CI com Java.

## Evidências

`tsc`/ESLint sem erros; Jest `2 passed`; Flutter `+2`; analyzer `No issues found`.

## Commit

Commit local único desta task.

## Push

Não realizado, conforme solicitado.

## Hash do commit

O `HEAD` desta task; hash informado na resposta final.

## Branch

`main`
