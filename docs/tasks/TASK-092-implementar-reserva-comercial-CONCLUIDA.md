# TASK-092 — Concluída (2026-08-28)

## Resumo
Reserva comercial temporária de estoque implementada com configuração organizacional de expiração, flag central de feature toggle e funções server-side para criar, liberar, consumir e expirar reservas. O fluxo reaproveita o saldo agregado por variante/warehouse, debita apenas `reservedQuantity` durante a reserva e evita débito duplo ao consumir a reserva na futura submissão do pedido.

## Agentes utilizados
- `flutter-senior-architect`

## Arquivos criados
- `lib/features/inventory/domain/entities/stock_reservation.dart`
- `lib/features/inventory/domain/value_objects/stock_reservation_status.dart`
- `test/features/inventory/domain/entities/stock_reservation_test.dart`
- `functions/src/inventory/stock-reservation-shared.ts`
- `functions/src/inventory/create-stock-reservation.ts`
- `functions/src/inventory/release-stock-reservation.ts`
- `functions/src/inventory/consume-stock-reservation.ts`
- `functions/src/inventory/expire-stock-reservations.ts`
- `functions/test/inventory/stock-reservation-shared.test.ts`

## Arquivos alterados
- `lib/core/feature_flags/feature_flag_registry.dart`
- `lib/features/inventory/inventory.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.dart`
- `lib/features/organizations/domain/value_objects/organization_settings.freezed.dart`
- `lib/features/organizations/data/dtos/organization_settings_dto.dart`
- `lib/features/organizations/data/mappers/organization_mapper.dart`
- `lib/features/organizations/domain/usecases/update_organization_settings_use_case.dart`
- `test/core/feature_flags/feature_flag_registry_test.dart`
- `test/core/feature_flags/fake_feature_flag_service_test.dart`
- `test/features/organizations/domain/value_objects/organization_settings_test.dart`
- `test/features/organizations/data/mappers/organization_mapper_test.dart`
- `functions/src/index.ts`
- `functions/src/organizations/create-organization.ts`
- `firestore.rules`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture/feature-first para os contratos Flutter e Functions server-side para toda mutação crítica. A lógica de transição de saldo reservável foi centralizada em helpers puros no backend, enquanto as callables apenas validam permissão, carregam tenant real e aplicam transações no Firestore.

## Regras de negócio implementadas
- Reserva nunca ultrapassa o saldo vendável disponível no momento da criação.
- Reserva só movimenta `reservedQuantity`; o físico só é reduzido no consumo final da reserva.
- Liberação e expiração devolvem a quantidade reservada ao saldo vendável.
- Consumo reduz `physicalQuantity` e `reservedQuantity` na mesma operação para evitar decremento duplicado.
- Expiração da reserva é configurável por organização entre 15 e 60 minutos.

## Regras Firebase implementadas
- Nova subcoleção `organizations/{organizationId}/stockReservations/{reservationId}` com leitura apenas para membro ativo do tenant e escrita client-side totalmente bloqueada.
- Callables de reserva revalidam membership real no backend antes de qualquer mutação.
- Expiração automática roda em Function agendada a cada 5 minutos.

## Analytics implementado
Nenhum evento novo nesta task. O foco permaneceu em infraestrutura transacional e governança de estoque.

## Crashlytics implementado
Nenhum fluxo específico novo.

## Impacto offline
Sem persistência local nova nesta task. A funcionalidade foi preparada server-side para ser consumida com segurança quando o fluxo de pedido em elaboração evoluir.

## Impacto multi-tenant
Todas as reservas, saldos e auditorias continuam rigorosamente escopados por `organizationId`.

## Testes criados
- Entidade `StockReservation`
- Registry/fake de feature flags para a nova flag de reserva
- Validação e round-trip do novo TTL em `OrganizationSettings`
- Suite Node pura da lógica de criação, overselling, liberação, consumo e expiração de reserva

## Comandos executados
- `dart run build_runner build`
- `flutter test test/features/inventory/domain/entities/stock_reservation_test.dart test/features/organizations/domain/value_objects/organization_settings_test.dart test/features/organizations/data/mappers/organization_mapper_test.dart test/core/feature_flags/feature_flag_registry_test.dart test/core/feature_flags/fake_feature_flag_service_test.dart`
- `npm run build` (em `functions/`)
- `npm test -- --runTestsByPath test/inventory/stock-reservation-shared.test.ts` (em `functions/`)
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`

## Resultado do formatter
`dart format --set-exit-if-changed .` passou sem alterações pendentes.

## Resultado do analyzer
`flutter analyze` sem issues.

## Resultado dos testes
- Testes Dart focados do escopo passaram.
- `flutter test` completo do repositório passou.
- `npm run build` das Functions passou.
- A suite Node pura da lógica de reserva passou.

## Decisões técnicas
- O timeout da reserva foi promovido para `OrganizationSettings`, porque a regra precisa ser tenant-aware e nunca hardcoded no client.
- A feature flag ficou registrada no catálogo central de Remote Config com default seguro desligado.
- A lógica aritmética crítica de reserva foi extraída para helpers puros testáveis sem depender de credenciais do Admin SDK.
- A criação da organização já nasce com timeout padrão de 15 minutos para manter compatibilidade com tenants novos.

## Riscos conhecidos
- A cobertura Node validada neste ambiente foi unitária/pura; a suíte Firestore-backed continua dependente de credenciais válidas ou Emulator funcional com Java.
- A integração do consumo com a submissão real do pedido depende da TASK-101.

## Pendências
- Acoplar `consumeStockReservation` ao fluxo definitivo de submissão do pedido na TASK-101.
- Adicionar cobertura Firestore Emulator quando o ambiente local tiver Java disponível para subir os emuladores.

## Evidências
- `feature_inventory_reservations_enabled` registrada no `FeatureFlagRegistry`.
- `stockReservationExpiresInMinutes` adicionada ao modelo de `OrganizationSettings`.
- Functions `createStockReservation`, `releaseStockReservation`, `consumeStockReservation` e `expireStockReservations` exportadas.

## Commit
Será realizado localmente sem push.

## Push
Não autorizado nesta conversa.

## Hash do commit
Pendente nesta etapa do arquivo; será preenchido após o commit local.

## Branch
`main`
