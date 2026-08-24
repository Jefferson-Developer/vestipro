# TASK-053 — Concluída (2026-08-24)

## Resumo

Implementada a segmentação dinâmica de clientes: uma entidade `CustomerSegment`
escopada por organização, com critérios combináveis via AND (reaproveitando os
filtros já existentes na carteira de TASK-051: status, UF/região, potencial e
última compra, mais um critério dinâmico de "categoria de produto comprada"),
persistência local, contagem de clientes em preview antes de salvar, RBAC de
visibilidade privado/compartilhado, e aplicação do segmento como filtro
rápido na página da carteira de clientes.

## Agentes utilizados

- `flutter-senior-architect` (checklist lido; implementação de domínio, dados,
  BLoC e DI feita diretamente).
- `flutter-ui-design-specialist` (checklist lido; UI reaproveita
  `AppFilterChip`, `AppModal`, `AppTextField`, `AppButton` do Design System).

## Arquivos criados

Domínio:
- `lib/features/customers/domain/value_objects/customer_segment_visibility.dart`
- `lib/features/customers/domain/entities/customer_segment_criteria.dart`
- `lib/features/customers/domain/entities/customer_segment.dart`
- `lib/features/customers/domain/entities/customer_segment_preview.dart`
- `lib/features/customers/domain/repositories/customer_segment_repository.dart`
- `lib/features/customers/domain/usecases/create_customer_segment_use_case.dart`
- `lib/features/customers/domain/usecases/list_customer_segments_use_case.dart`
- `lib/features/customers/domain/usecases/delete_customer_segment_use_case.dart`
- `lib/features/customers/domain/usecases/preview_customer_segment_count_use_case.dart`

Dados:
- `lib/features/customers/data/dtos/customer_segment_dto.dart`
- `lib/features/customers/data/datasources/customer_segment_data_source.dart`
- `lib/features/customers/data/datasources/shared_preferences_customer_segment_data_source.dart`
- `lib/features/customers/data/mappers/customer_segment_mapper.dart`
- `lib/features/customers/data/repositories/customer_segment_repository_impl.dart`

Apresentação:
- `lib/features/customers/presentation/bloc/customer_segment_event.dart`
- `lib/features/customers/presentation/bloc/customer_segment_state.dart`
- `lib/features/customers/presentation/bloc/customer_segment_bloc.dart`
- `lib/features/customers/presentation/widgets/customer_segment_quick_filters.dart`

Testes:
- `test/features/customers/domain/entities/customer_segment_criteria_test.dart`
- `test/features/customers/domain/entities/customer_segment_test.dart`
- `test/features/customers/domain/usecases/create_customer_segment_use_case_test.dart`
- `test/features/customers/domain/usecases/list_customer_segments_use_case_test.dart`
- `test/features/customers/domain/usecases/delete_customer_segment_use_case_test.dart`
- `test/features/customers/domain/usecases/preview_customer_segment_count_use_case_test.dart`
- `test/features/customers/data/repositories/customer_segment_repository_test.dart`
- `test/features/customers/presentation/bloc/customer_segment_bloc_test.dart`

Documentação:
- `docs/tasks/TASK-053-implementar-segmentacao-de-clientes-CONCLUIDA.md` (este arquivo).

## Arquivos alterados

- `lib/features/customers/customers.dart` — exporta os novos símbolos públicos
  da feature (entidades, repositório, use cases, bloc, widget).
- `lib/features/customers/presentation/pages/customer_portfolio_page.dart` —
  adiciona o parâmetro opcional `createSegmentBloc` a `CustomerPortfolioPage`
  e monta `CustomerSegmentQuickFilters` no topo do painel de filtros somente
  quando esse builder é fornecido (aditivo; nenhum call site existente foi
  obrigado a mudar).
- `lib/app/bootstrap.dart` — conecta `createSegmentBloc: () =>
  getIt<CustomerSegmentBloc>()` na rota real da carteira.
- `lib/app/injection.config.dart` — regenerado via `build_runner` para
  registrar os novos `@injectable`/`@LazySingleton`/`@lazySingleton`
  (mapper, datasource, repositório, use cases, bloc).
- `docs/tasks/TASKS.md` — checkbox da TASK-053 marcado e progresso atualizado
  para `53 / 220`.

Nenhum arquivo fora do escopo foi tocado; `lib/main.dart` não foi alterado.

## Arquitetura utilizada

Clean Architecture feature-first, seguindo exatamente o padrão já usado em
`customers/` (ex.: `customer_form_draft`): `Presentation (BLoC) → Use case →
Repository contract (domain) → Repository impl (data) → DataSource`. A UI
(`CustomerSegmentQuickFilters`) nunca acessa `SharedPreferences` diretamente —
só dispara eventos no `CustomerSegmentBloc`. `PreviewCustomerSegmentCountUseCase`
reaproveita `ListCustomerPortfolioUseCase` (em vez de duplicar a resolução de
RBAC/visibilidade de carteira) para garantir que o preview de um segmento
nunca conte clientes que o usuário não poderia ver na carteira.

## Regras de negócio implementadas

- Segmento sempre escopado por `organizationId`; `CustomerSegmentRepository`
  só lista por organização, nunca entre organizações.
- Critérios combináveis via AND (status, UF, potencial, última compra e
  categoria de produto comprada) — `CustomerSegmentCriteria.combinedFacetCount`
  e o teste dedicado comprovam a combinação de 3+ critérios simultâneos.
- Segmento "privado" visível apenas ao criador; "compartilhado" visível a
  qualquer membro da organização com `Capability.customerView` (mesma
  capability já usada para a carteira) — `CustomerSegment.isVisibleTo`.
- Apenas o criador pode editar/excluir um segmento, mesmo quando
  compartilhado (`CustomerSegment.isEditableBy`,
  `DeleteCustomerSegmentUseCase`).
- Contagem de clientes calculada sob demanda antes de salvar
  (`PreviewCustomerSegmentCountUseCase`), com um teto de 100 clientes por
  chamada (`previewLimit`) e uma flag `isAtLeastCount` para indicar quando o
  número real pode ser maior — evita centenas de leituras client-side numa
  organização grande.

## Regras Firebase implementadas

Nenhuma regra de Firestore/Storage nova: a persistência de `CustomerSegment`
usa a mesma estratégia local (`SharedPreferences`) que `CustomerRepository`
já usa hoje para clientes, documentada como "até a implementação
remota/outbox existir". Quando o backend de clientes migrar para
Firestore+outbox (fora do escopo desta task), `CustomerSegmentRepositoryImpl`
deve migrar junto, escopado por `organizationId` nas regras, como já é regra
geral do projeto.

## Analytics implementado

Nenhum evento de analytics novo foi adicionado nesta task — não havia um
evento de "segmento" já definido em `AnalyticsEvents` para reaproveitar, e
criar um novo estava fora do escopo técnico descrito na task. Fica como
pendência recomendada (ver "Pendências").

## Crashlytics implementado

Nenhuma instrumentação nova de Crashlytics — os fluxos passam pelos mesmos
`AppResult`/`Failure` já tratados pelo restante da feature; erros
inesperados de persistência local são convertidos em `UnexpectedFailure`
como o restante do repositório de clientes já faz.

## Impacto offline

Segmentos são 100% locais (SharedPreferences), logo funcionam totalmente
offline, exatamente como a carteira de clientes hoje. Não há sync/outbox
ainda porque `CustomerRepository`/carteira também não têm — mesma limitação
documentada, não uma regressão introduzida por esta task.

## Impacto multi-tenant

Toda leitura/escrita de segmento é filtrada por `organizationId` em
`CustomerSegmentDataSource`/`CustomerSegmentRepositoryImpl`
(`customer_segments_$organizationId`), e `ListCustomerSegmentsUseCase`/
`CustomerSegment.isVisibleTo` aplicam RBAC de visibilidade por cima disso.
Testado explicitamente em
`test/features/customers/data/repositories/customer_segment_repository_test.dart`
("scopes segments strictly by organization").

## Testes criados

- Critérios combináveis (3+ facetas via AND), normalização, serialização
  JSON round-trip e o comportamento documentado de "categoria comprada" não
  restringir ainda (`customer_segment_criteria_test.dart`).
- Visibilidade privado/compartilhado e permissão de edição/exclusão
  (`customer_segment_test.dart`).
- Criação de segmento com validação de campos obrigatórios
  (`create_customer_segment_use_case_test.dart`).
- RBAC de listagem: segmento privado de outro usuário não aparece; segmento
  compartilhado aparece (`list_customer_segments_use_case_test.dart`).
- Exclusão restrita ao criador, mesmo quando compartilhado
  (`delete_customer_segment_use_case_test.dart`).
- Preview de contagem reaproveitando `ListCustomerPortfolioUseCase`,
  incluindo o teto de 100 e propagação de falha
  (`preview_customer_segment_count_use_case_test.dart`).
- Persistência local e reaplicação após "reinício" (nova instância de
  repositório/datasource), escopo por organização e exclusão permanente
  (`customer_segment_repository_test.dart`).
- BLoC: carregamento filtrado por RBAC, salvar e atualizar lista, remover
  segmento do estado (`customer_segment_bloc_test.dart`).

## Comandos executados

```bash
dart run build_runner build --delete-conflicting-outputs
dart format --set-exit-if-changed .
flutter analyze
flutter test test/features/customers/
flutter test
```

## Resultado do formatter

```
Formatted 754 files (4 changed) in 2.69 seconds.
```
(rodado novamente após: `Formatted 754 files (0 changed) in 2.34 seconds.`;
depois de adicionar os testes: `Formatted 762 files (8 changed)` seguido de
`0 changed` numa nova checagem implícita pelo próprio `flutter analyze`
limpo.)

## Resultado do analyzer

```
Analyzing VestiPro...
No issues found! (ran in 11.6s)
```

## Resultado dos testes

```
flutter test test/features/customers/
...
00:05 +86: All tests passed!
```

```
flutter test
...
00:39 +1147: All tests passed!
```

## Decisões técnicas

- **Preview via reuso, não duplicação de RBAC**: `PreviewCustomerSegmentCountUseCase`
  chama `ListCustomerPortfolioUseCase` (limit=100) em vez de reimplementar a
  resolução de visibilidade (ADMIN/gerente de equipe/vendedor). Isso evita
  duplicar uma regra de negócio sensível de RBAC e garante que o preview
  nunca vaze contagem de clientes fora do escopo do usuário.
- **UI aditiva**: `CustomerPortfolioPage` ganhou um parâmetro opcional
  `createSegmentBloc`; quando `null` (como em todos os testes de widget
  pré-existentes), o comportamento é idêntico ao anterior. Isso evitou
  qualquer alteração nos testes/call sites já existentes da carteira.
- **Sem "update" de segmento**: o escopo técnico só exige criar, salvar,
  reaplicar e listar com RBAC; um caso de uso de atualização foi
  deliberadamente omitido para não expandir a superfície da task além do
  pedido — ver "Pendências".
- **Categoria de produto comprada não filtra ainda**: `CustomerSegmentCriteria.
  purchasedCategoryCodes` é persistido e testado, mas
  `toPortfolioFilters()`/`PreviewCustomerSegmentCountUseCase` não o aplicam
  como restrição real, pois não existe histórico de pedidos por categoria
  ainda (depende de EPIC-08/13). Isso é a limitação explicitamente prevista
  no escopo da task ("preparado para plugar quando o histórico de pedidos
  existir").

## Riscos conhecidos

- Sem paginação/backend real para segmentos (SharedPreferences local),
  assim como a carteira de clientes hoje — se/quando `CustomerRepository`
  migrar para Firestore+outbox, `CustomerSegmentRepositoryImpl` deve migrar
  junto para não ficar dessincronizado.
- Preview de contagem é limitado a 100 clientes por chamada
  (`previewLimit`); em organizações muito grandes, o preview mostra "100+"
  em vez do total exato — decisão deliberada para não disparar centenas de
  leituras client-side, documentada em `isAtLeastCount`.

## Pendências

- Não há caso de uso de "atualizar critérios de um segmento existente"; a
  regra de negócio "alterar critérios não deve afetar retroativamente
  relatórios já gerados" ficou documentada como preocupação de design (não
  há hoje nenhum relatório que consuma segmentos para violar essa regra),
  mas deve ser revisitada quando um consumidor de relatórios por segmento
  existir.
- Nenhum evento de Analytics específico para criação/aplicação/exclusão de
  segmento foi adicionado; recomenda-se avaliar a adição de eventos como
  `customer_segment_created`/`customer_segment_applied` quando a métrica de
  adoção da funcionalidade for necessária.
- O critério "categoria de produto comprada" ainda não filtra de fato
  (ver "Decisões técnicas") até o histórico de pedidos existir.

## Evidências

Saídas reais de `dart format`, `flutter analyze` e `flutter test` (feature e
suíte completa) coladas nas seções acima, obtidas rodando os comandos neste
repositório em 2026-08-24.

## Commit

Único commit local contendo implementação + `docs/tasks/TASKS.md` atualizado
+ esta documentação de conclusão.

## Push

Não realizado — push não foi autorizado nesta rodada.

## Hash do commit

Ver saída de `git rev-parse HEAD` reportada na resposta final desta task.

## Branch

`main`
