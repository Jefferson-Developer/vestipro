# TASK-183 — Concluída (2026-09-07)

## Resumo

Integração com WhatsApp Business Cloud API implementada com consentimento explícito, templates
aprovados, credenciais em secrets, histórico de entrega e entradas no pedido, catálogo e central de
notificações comerciais.

## Agentes utilizados

- `flutter-senior-architect`: Clean Architecture, Functions, segurança, tenant, DI e testes.
- `flutter-ui-design-specialist`: compositor responsivo e estados de consentimento/envio/histórico.
- `vestipro-sales-representative-specialist`: fluxo curto de envio e falhas acionáveis.

## Arquivos criados

- `functions/src/whatsapp/` e `functions/test/whatsapp/`.
- `lib/features/whatsapp_business/` e `test/features/whatsapp_business/`.
- Este relatório de conclusão.

## Arquivos alterados

- `functions/src/index.ts`, `firestore.rules` e `firestore.indexes.json`.
- `lib/app/bootstrap.dart`, `lib/app/injection.config.dart`.
- Analytics, notificações, pedido, produto e compartilhamento de catálogo.
- `test/core/analytics/analytics_events_test.dart` e `docs/tasks/TASKS.md`.

## Arquitetura utilizada

Feature-first + Clean Architecture: widget → Cubit → use cases → repository →
`CloudFunctionsService` → callable. Consentimento, autorização, template, telefone, tenant e payload
do catálogo são revalidados no servidor.

## Regras de negócio implementadas

- Nenhum envio sem opt-in `accepted`; revogação bloqueia imediatamente.
- Transições válidas de `requested/accepted/refused/revoked`, com trilha de auditoria.
- Envio exclusivamente por template aprovado; texto livre não é aceito.
- Cadastro de template aprovado restrito a OWNER/ADMIN.
- Falhas de token, rate limit, telefone e template têm mensagens compreensíveis e reenvio manual.
- `CatalogShare` ativo pode acompanhar o envio; pedido e notificação carregam o cliente correto.
- Webhook assinado atualiza `sent/delivered/read/failed` sem regressão em evento fora de ordem.

## Regras Firebase implementadas

Escrita/leitura direta de opt-ins, templates e mensagens foi negada; toda operação passa pelas
Functions com Membership ativa. Foi criado índice `customerId + createdAt` para o histórico.
Secrets: `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_VERIFY_TOKEN` e
`WHATSAPP_APP_SECRET`.

## Analytics implementado

- `whatsapp_opt_in_requested`.
- `whatsapp_message_sent` sem telefone, nome ou outra PII.

## Crashlytics implementado

Nenhuma captura específica; erros esperados viram `Failure` e estado recuperável na UI.

## Impacto offline

O vínculo `customerId` da notificação permanece no cache offline. Solicitação, envio e atualização
de entrega exigem rede por dependerem da API da Meta e de validação server-side.

## Impacto multi-tenant

Todas as coleções ficam sob `organizations/{organizationId}`; a Function valida a Membership real e
a existência do cliente no mesmo tenant antes de ler ou enviar.

## Testes criados

- Functions: transições do opt-in, template inválido, opt-in ausente/revogado, sucesso da API Meta,
  token expirado, rate limit, assinatura/status e evento fora de ordem.
- Widgets: solicitação de opt-in, template/variáveis, sucesso, falha/reenvio e histórico de entrega.
- Regressão: analytics, notificações e alerta comercial de pedido.

## Comandos executados

```text
dart run build_runner build
dart format --set-exit-if-changed .
flutter analyze
flutter analyze <arquivos e diretórios da task>
flutter test
flutter test test/core/analytics/analytics_events_test.dart test/core/notifications test/features/orders/domain/usecases/process_order_commercial_alert_use_case_test.dart test/features/whatsapp_business
npm --prefix functions run build
npm --prefix functions run lint -- --quiet
npm --prefix functions test -- --runInBand test/whatsapp
firebase emulators:exec --only firestore "npm test -- --runInBand test/whatsapp"
```

## Resultado do formatter

Arquivos Dart formatados. O formatter também normalizou os três arquivos dirty preexistentes, que
permanecem fora do commit desta task.

## Resultado do analyzer

- Escopo da task: `No issues found`.
- Projeto completo: 15 infos preexistentes fora do escopo; nenhum erro novo da task.

## Resultado dos testes

- Flutter relacionado: 54 testes passando.
- Jest WhatsApp: 14 testes passando; TypeScript e ESLint passando.
- Suíte Flutter completa: 3.150 testes executados, com duas falhas preexistentes no bootstrap
  (`PushDeviceMapper` ausente/Crashlytics sem mock) e na taxonomia Analytics; a taxonomia foi
  atualizada e seu teste passou na rodada relacionada.
- Firestore Emulator não iniciou porque Java não está instalado (`spawn java ENOENT`).

## Decisões técnicas

- Sempre usar template, inclusive dentro da janela de 24 horas, como política mais restritiva.
- Secrets ficam somente nas Functions e a assinatura SHA-256 do webhook é validada.
- Histórico limitado aos 50 envios mais recentes, ordenados no servidor.
- Notificação comercial só oferece WhatsApp quando possui `customerId`; o compositor revalida opt-in.

## Riscos conhecidos

- Configurar os quatro secrets e a URL/verificação do webhook antes do deploy.
- Executar a suíte de Rules no Emulator/CI com Java.
- O status de aprovação cadastrado deve corresponder a um template já aprovado na conta Meta.

## Pendências

- Provisionamento externo da conta WhatsApp Business, templates Meta, secrets e webhook.
- Validação end-to-end contra uma conta sandbox/produção da Meta.

## Evidências

Analyzer de escopo sem issues; Jest `14 passed`; Flutter relacionado `54 passed`; `tsc` e ESLint sem
erros.

## Commit

Commit local único desta task.

## Push

Não realizado, conforme solicitado.

## Hash do commit

O `HEAD` desta task; hash informado na resposta final.

## Branch

`main`
