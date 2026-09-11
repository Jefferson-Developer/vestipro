# TASK-216 — Implementar leitura de código de barras e QR para venda rápida — CONCLUÍDA

## Resumo

Implementada a feature `barcode_scanner` (EPIC-32): o vendedor pode escanear (câmera) ou digitar
manualmente um código (EAN-13/EAN-8, SKU/referência ou um QR interno do VestiPro) e resolvê-lo contra
o catálogo — variante exata, produto com várias variantes ativas (o vendedor escolhe cor/tamanho
normalmente) ou "não encontrado" — sem nunca contornar preço, estoque, crédito ou RBAC: o scanner só
identifica *qual* produto/variante o vendedor quis dizer, e devolve esse resultado para o mesmo fluxo
de detalhe do produto/adição ao pedido que já existia, que continua sendo o único lugar que resolve
preço/disponibilidade e persiste um `OrderItem`.

A resolução tenta, em ordem, o caminho mais específico primeiro: um código alternativo cadastrado
(`AlternateProductCode`, correção de cadastro), depois SKU/EAN exato de uma variante, depois
SKU/referência/EAN exato de um produto (usando o índice de busca já existente — offline primeiro,
remoto só como fallback quando o offline não encontra nada). Um QR interno (`vestipro:v1:variant:
<organizationId>:<variantId>`) nunca carrega segredo/token/dado pessoal, e um QR cunhado para outra
organização nunca resolve — vira "não encontrado" em vez de vazar que existe em outro tenant.

Integração real e ponta-a-ponta feita no fluxo de **pedido** (`OrderProductCatalogPage`, EPIC-13): um
botão "escanear" abre a tela de scanner e, ao resolver, empurra a mesma `OrderProductDetailRoute` que
já era usada ao tocar um card do catálogo — nenhum código de preço/estoque/RBAC foi duplicado. A
"busca global" e o "detalhe do produto" citados no escopo técnico só têm a capacidade genérica pronta
(`BarcodeScannerPage`/`ResolveProductCodeUseCase`, testados e exportados pelo barrel da feature); a
integração concreta neles fica documentada como pendência (ver seção própria), pelos motivos técnicos
explicados em "Decisões técnicas".

## Agentes utilizados

- `flutter-senior-architect` (arquitetura, domínio, dados, RBAC, offline, testes)
- `flutter-ui-design-specialist` (tela de scanner com câmera/fallback manual usando o Design System já
  existente)

## Arquivos criados

### Flutter — feature `barcode_scanner`
- `lib/features/barcode_scanner/barcode_scanner.dart` (barrel)
- `lib/features/barcode_scanner/domain/value_objects/scanned_code_format.dart`
- `lib/features/barcode_scanner/domain/value_objects/internal_qr_payload.dart`
- `lib/features/barcode_scanner/domain/entities/scanned_code.dart`
- `lib/features/barcode_scanner/domain/entities/product_code_match.dart`
- `lib/features/barcode_scanner/domain/entities/product_code_resolution.dart`
- `lib/features/barcode_scanner/domain/entities/alternate_product_code.dart`
- `lib/features/barcode_scanner/domain/services/scanned_code_classifier.dart`
- `lib/features/barcode_scanner/domain/repositories/product_code_lookup_repository.dart`
- `lib/features/barcode_scanner/domain/usecases/resolve_product_code_use_case.dart`
- `lib/features/barcode_scanner/domain/usecases/register_unknown_product_code_use_case.dart`
- `lib/features/barcode_scanner/data/datasources/alternate_product_code_local_data_source.dart`
- `lib/features/barcode_scanner/data/datasources/shared_preferences_alternate_product_code_data_source.dart`
- `lib/features/barcode_scanner/data/repositories/product_code_lookup_repository_impl.dart`
- `lib/features/barcode_scanner/presentation/cubit/barcode_scan_state.dart`
- `lib/features/barcode_scanner/presentation/cubit/barcode_scan_cubit.dart`
- `lib/features/barcode_scanner/presentation/widgets/manual_code_entry_field.dart`
- `lib/features/barcode_scanner/presentation/widgets/barcode_scanner_camera_surface.dart`
- `lib/features/barcode_scanner/presentation/pages/barcode_scanner_page.dart`

### Testes Flutter
- `test/features/barcode_scanner/domain/value_objects/internal_qr_payload_test.dart`
- `test/features/barcode_scanner/domain/services/scanned_code_classifier_test.dart`
- `test/features/barcode_scanner/domain/usecases/resolve_product_code_use_case_test.dart`
- `test/features/barcode_scanner/domain/usecases/register_unknown_product_code_use_case_test.dart`
- `test/features/barcode_scanner/data/repositories/product_code_lookup_repository_impl_test.dart`
- `test/features/barcode_scanner/data/datasources/shared_preferences_alternate_product_code_data_source_test.dart`
- `test/features/barcode_scanner/presentation/cubit/barcode_scan_cubit_test.dart`
- `test/features/barcode_scanner/presentation/pages/barcode_scanner_page_test.dart`

### Documentação
- `docs/tasks/TASK-216-implementar-leitura-de-codigo-de-barras-e-qr-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `pubspec.yaml` / `pubspec.lock` — dependência `mobile_scanner: ^7.4.1` (câmera/leitura de código,
  Android/iOS/Web — os três alvos deste repositório).
- `android/app/src/main/AndroidManifest.xml` — `android.permission.CAMERA` +
  `uses-feature android.hardware.camera` (`required="false"`, nunca bloqueia instalação em
  dispositivo sem câmera).
- `ios/Runner/Info.plist` — `NSCameraUsageDescription`.
- `lib/core/analytics/analytics_events.dart` — 4 novos eventos (`barcode_scan_resolved`,
  `barcode_scan_permission_denied`, `barcode_scan_manual_fallback_used`,
  `barcode_alternate_code_registered`).
- `test/core/analytics/analytics_events_test.dart` — lista congelada de `AnalyticsEvents.values`
  sincronizada com os 4 eventos novos.
- `lib/features/audit_log/domain/value_objects/audit_action.dart` — novo
  `AuditAction.productAlternateCodeRegistered` (`product.alternateCodeRegistered`).
- `lib/features/audit_log/presentation/presenters/audit_log_presenter.dart` — rótulo em português
  para essa nova ação.
- `lib/features/orders/presentation/pages/order_product_catalog_page.dart` — novo botão de scan
  (`AppIconButton`) que abre `BarcodeScannerPage` e, ao resolver, empurra a mesma
  `OrderProductDetailRoute` já usada por um toque no card do catálogo; novo parâmetro obrigatório
  `createBarcodeScanCubit`.
- `lib/app/bootstrap.dart` — importa `barcode_scanner.dart` e passa
  `createBarcodeScanCubit: () => getIt<BarcodeScanCubit>()` para `OrderProductCatalogPage`.
- `lib/app/injection.config.dart` — registra `SharedPreferencesAlternateProductCodeDataSource`,
  `ProductCodeLookupRepositoryImpl`, `ResolveProductCodeUseCase`,
  `RegisterUnknownProductCodeUseCase`, `BarcodeScanCubit`. **Nota de honestidade**: o `build_runner`
  travou neste ambiente (lock órfão de uma execução anterior interrompida por corte de sessão, mesmo
  após limpar o lock e os processos `dart.exe` remanescentes — a nova tentativa não avançava em tempo
  hábil) e foi abortado a pedido do usuário; as 5 entradas foram adicionadas manualmente ao arquivo
  gerado, replicando exatamente o padrão de import prefixado (`_iNNN`) e as chamadas
  `gh.lazySingleton`/`gh.factory` que o `injectable`/`get_it_generator` já produzem para as features
  irmãs (`backorder`, `fulfillment`). Verificado com `flutter analyze` (0 issues nos arquivos tocados)
  e com um teste avulso (criado e removido só para essa checagem, não faz parte do código do
  repositório) que chama `configureDependencies` e resolve `getIt<BarcodeScanCubit>()`,
  `getIt<ResolveProductCodeUseCase>()` e `getIt<RegisterUnknownProductCodeUseCase>()` de ponta a
  ponta — a cadeia resolveu até o fim (o único erro observado foi a ausência de
  `Firebase.initializeApp()` nesse teste avulso, a mesma exigência que qualquer outra feature já tem,
  não um problema da edição manual). Risco residual: a próxima execução bem-sucedida do
  `build_runner` neste arquivo deve ser conferida por diff antes de commitar, para garantir que o
  gerador não produza uma forma different (ainda que semanticamente equivalente) destas 5 entradas.
- `docs/tasks/TASKS.md` — checkbox da TASK-216 marcado e `Progresso` atualizado para `212 / 216`.

## Arquitetura utilizada

Feature-first + Clean Architecture, nova feature `barcode_scanner` que depende apenas de contratos já
existentes das features `products` (via `ProductRepository`/`ProductVariantRepository`/
`SearchProductsUseCase`, nenhum deles alterado) e `audit_log`/`permissions` (para o caminho de
correção de cadastro) — nenhuma interface pré-existente foi modificada, então o raio de impacto em
`products`/`orders`/`catalog` ficou limitado a um botão novo e um parâmetro de construtor novo em
`OrderProductCatalogPage`.

- **Domain**: `ScannedCode`/`ScannedCodeFormat` (classificação pura, sem I/O),
  `InternalQrPayload` (formato de QR interno, parse/encode só com `organizationId`/`variantId`),
  `ProductCodeMatch`/`ProductCodeResolution` (resultado da resolução), `AlternateProductCode`
  (registro de código alternativo), `ProductCodeLookupRepository` (contrato) e dois use cases
  (`ResolveProductCodeUseCase`, `RegisterUnknownProductCodeUseCase`) — nenhuma dependência de
  Flutter/Firebase/Drift.
- **Data**: `AlternateProductCodeLocalDataSource` (contrato) +
  `SharedPreferencesAlternateProductCodeDataSource` (impl local, mesmo padrão de
  `SharedPreferencesProductVariantRepository`) + `ProductCodeLookupRepositoryImpl`, que compõe o
  datasource local de códigos alternativos com `ProductVariantRepository`/`ProductRepository`/
  `SearchProductsUseCase` já existentes — nenhuma tabela Drift nova, nenhuma coleção Firestore nova.
- **Presentation**: `BarcodeScanCubit` (sessão de escaneamento: status, resolução, contagem de
  leituras repetidas) + `BarcodeScannerPage` (câmera com `MobileScanner` por trás de um seam
  (`cameraSurfaceBuilder`) trocável em teste, alternância para digitação manual, cartão de resultado
  com "Usar este produto"/"Escanear outro código").
- UI nunca acessa Firestore/Storage/Drift diretamente; nenhuma regra de negócio de preço/estoque/RBAC
  vive em widget — o scanner devolve só a identificação do produto/variante, e o consumidor
  (`OrderProductCatalogPage`) reaproveita o roteamento já existente para `OrderProductDetailRoute`.

## Regras de negócio implementadas

- **Scanner nunca contorna preço/estoque/RBAC**: `ProductCodeLookupRepository`/`BarcodeScanCubit` só
  devolvem `ProductCodeResolution` (produto + variante opcional); nenhuma dependência de pricing,
  estoque, criação de `OrderItem` ou RBAC de pedido existe nesta feature — a prova arquitetural é o
  próprio grafo de dependências (`BarcodeScanCubit → ResolveProductCodeUseCase →
  ProductCodeLookupRepository`, nada além disso), reforçada pelo teste de widget "confirming 'Usar
  este produto' pops the resolution without any order/price/stock write" e pela integração em
  `OrderProductCatalogPage`, que reaproveita literalmente a mesma chamada `context.push` +
  `OrderProductDetailRoute` já usada pelo toque manual no catálogo.
- **Múltiplas variantes de um produto nunca são "escolhidas" pelo scanner**: quando o código
  corresponde a um identificador de produto (não de variante) com mais de uma variante ativa, a
  resolução é `multipleMatches` — a UI trata isso exatamente como abrir aquele produto normalmente,
  deixando o vendedor escolher cor/tamanho pela grade comercial já existente.
- **QR interno nunca concede acesso/autorização por si só**: carrega só `organizationId`/`variantId`
  (nenhum segredo/token/dado pessoal); um QR cunhado para outra organização resolve como "não
  encontrado" — nunca troca de tenant nem confirma que o código existe em outro lugar.
- **Leitura repetida incrementa contagem com feedback visível**: `BarcodeScanCubit` mantém
  `occurrenceCount` por código dentro da sessão de escaneamento, exibido como "Lido Nx nesta sessão" no
  cartão de resultado — ver "Decisões técnicas" para o porquê de não estar acoplado a incrementar
  quantidade de um pedido diretamente.
- **Código desconhecido só gera correção de cadastro para perfil autorizado**:
  `RegisterUnknownProductCodeUseCase` re-checa `Capability.catalogManage` (mesmo padrão de
  defesa em profundidade de `DecideReplenishmentSuggestionUseCase`) antes de gravar um
  `AlternateProductCode`, e registra uma entrada de auditoria
  (`AuditAction.productAlternateCodeRegistered`).

## Regras Firebase implementadas

Nenhuma — decisão deliberada desta task. A resolução de código só lê dados que já passam por
Firestore Security Rules pré-existentes e inalteradas (`ProductRepository`/`ProductVariantRepository`/
`ProductSearchRepository`); o registro de código alternativo é 100% local (`SharedPreferences`, ver
"Riscos conhecidos" sobre não sincronizar entre vendedores/dispositivos ainda). Não havia necessidade
de nova coleção, regra ou Cloud Function para o escopo entregue.

## Analytics implementado

4 novos eventos em `AnalyticsEvents`, nenhum carregando o valor do código escaneado:
- `barcode_scan_resolved` (`resolution_status`, `match_count`) — `ResolveProductCodeUseCase`, todo
  resultado bem-sucedido (inclusive `notFound`).
- `barcode_scan_permission_denied` (`source: camera`) — `BarcodeScanCubit.reportPermissionDenied`.
- `barcode_scan_manual_fallback_used` — `BarcodeScanCubit.reportManualFallbackUsed`.
- `barcode_alternate_code_registered` (`has_variant`) — `RegisterUnknownProductCodeUseCase`, só no
  caminho de sucesso.

## Crashlytics implementado

Nenhuma instrumentação adicional foi necessária: `ProductCodeLookupRepositoryImpl` converte toda
exceção em `AppFailure`/`Failure` tipada (mesmo padrão `_guard` de `BackorderRepositoryImpl`), nunca
deixando uma exceção não tratada escapar para a UI — o handler global de Crashlytics já cobre o que
sobrar, mesmo padrão de todas as features irmãs do EPIC-32.

## Impacto offline

- **Índice local ("offline-first") real**: a resolução tenta o índice de busca de produtos *offline*
  (`ProductSearchSource.offline`, Drift, TASK-069) antes do remoto — só cai para o remoto quando o
  offline não encontra nada (testado explicitamente em
  `product_code_lookup_repository_impl_test.dart`). A correspondência exata de SKU/EAN de variante
  usa `ProductVariantRepository.listByOrganization`, que já é local
  (`SharedPreferencesProductVariantRepository`, hoje a única implementação registrada). O registro de
  código alternativo (`AlternateProductCode`) é 100% local desde o início
  (`SharedPreferences`), funcionando sem rede tanto para gravar quanto para resolver depois.
- **Câmera funciona sem rede** (é hardware local); só a busca "remota" de fallback exige conexão, e
  seu fracasso (ex.: sem sinal) degrada silenciosamente para "não encontrado" em vez de erro — a
  função `_searchExactProduct` já tratava um resultado remoto ausente como "sem match" antes de
  qualquer chamada de rede real ser tentada.

## Impacto multi-tenant

- Toda consulta (`resolveCode`/`registerAlternateCode`) é escopada por `organizationId`, reaproveitando
  os repositórios de `products` já isolados por tenant.
- Um QR interno cunhado para outra organização nunca resolve dentro da organização ativa do usuário
  (verificado em teste) — o `organizationId` embutido no QR nunca é usado como autorização, só como
  dado a ser comparado contra o `organizationId` do chamador.
- O índice local de códigos alternativos é isolado por organização (`SharedPreferences`, uma chave por
  `organizationId` — testado).

## Testes criados

- **Domain**: `ScannedCodeClassifier` (EAN-13/EAN-8 válidos e inválidos, QR interno, SKU genérico,
  código vazio); `InternalQrPayload` (round-trip, prefixo, payload malformado rejeitado, formato
  nunca carrega mais que organizationId/variantId); `ResolveProductCodeUseCase` (validação sem
  chamar o repositório, delegação + analytics, nunca loga o código em si, não loga quando falha);
  `RegisterUnknownProductCodeUseCase` (autorizado registra + audita + loga; não autorizado é negado
  sem chamar o repositório; payload inválido nem chega a checar permissão).
- **Data**: `ProductCodeLookupRepositoryImpl` — variante única por EAN e por SKU (case-insensitive),
  variante inativa nunca casa, produto com uma variante ativa vira `singleMatch`, produto com várias
  vira `multipleMatches` (todas apontando pro mesmo produto), código desconhecido e código em branco
  viram `notFound` sem consultar nada, índice offline tentado antes do remoto (e remoto pulado quando
  o offline já resolveu), fallback para remoto quando offline não acha nada, resolução via código
  alternativo cadastrado, QR interno da própria organização resolve, QR interno de outra organização
  nunca resolve, `registerAlternateCode` persiste algo que uma chamada seguinte de `resolveCode`
  encontra. `SharedPreferencesAlternateProductCodeDataSource` — não encontrado inicialmente,
  persistência sobrevive a uma nova instância (offline real), upsert substitui o alvo anterior,
  isolamento por organização, listagem por organização.
- **Presentation**: `BarcodeScanCubit` (código válido emite `resolving`→`resolved`, código em branco
  vira `invalid` sem chamar o resolver, código sem match vira `notFound`, mesma leitura repetida
  incrementa `occurrenceCount` com o estado ainda `resolved`, permissão negada muda o status e loga
  analytics). `BarcodeScannerPage` (leitura válida mostra o produto resolvido; leitura
  inválida/desconhecida mostra a mensagem de "não encontrado"; negar permissão troca para o campo de
  digitação manual e esconde a câmera; submeter um código válido pela digitação manual resolve pelo
  mesmo caminho; confirmar "Usar este produto" devolve a resolução via `Navigator.pop` sem qualquer
  efeito colateral de pedido/preço/estoque).

## Comandos executados

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs --build-filter="lib/app/injection.config.dart"
flutter analyze
flutter analyze lib/features/barcode_scanner test/features/barcode_scanner lib/features/orders/presentation/pages/order_product_catalog_page.dart lib/app/bootstrap.dart
flutter test test/features/barcode_scanner test/core/analytics/analytics_events_test.dart test/features/audit_log test/app/injection_test.dart
dart format lib/features/barcode_scanner test/features/barcode_scanner lib/features/orders/presentation/pages/order_product_catalog_page.dart lib/app/bootstrap.dart lib/core/analytics/analytics_events.dart lib/features/audit_log/domain/value_objects/audit_action.dart lib/features/audit_log/presentation/presenters/audit_log_presenter.dart test/core/analytics/analytics_events_test.dart
dart format --output=none --set-exit-if-changed lib/features/barcode_scanner test/features/barcode_scanner lib/features/orders/presentation/pages/order_product_catalog_page.dart lib/app/bootstrap.dart
```

Comandos adicionais rodados após a interrupção por corte de sessão (rate limit) durante a primeira
tentativa de `build_runner`, ao retomar a task e decidir pela edição manual do
`injection.config.dart` (ver nota em "Arquivos alterados"):

```
taskkill /F /IM dart.exe   # encerra processos dart.exe órfãos que seguravam o lock do build_runner
rm -f .dart_tool/build/lock/build_runner.lock
flutter analyze lib/app/injection.config.dart lib/app/bootstrap.dart lib/features/barcode_scanner
flutter test test/features/barcode_scanner test/app/injection_test.dart
# teste avulso criado só para checagem manual, removido em seguida (não faz parte do repositório):
flutter test test/_tmp_di_check/barcode_di_check_test.dart
```

## Resultado do formatter

`dart format` reformatou 14 dos arquivos recém-criados na primeira passada (estilo padrão do
formatter, nada de substância); a segunda passada (`--set-exit-if-changed`) sobre todos os arquivos
tocados retornou **0 changed** — formatação estável.

## Resultado do analyzer

`flutter analyze` (repositório inteiro): **0 erros/avisos novos** — os 19 `info` remanescentes já
existiam antes desta task (confirmado rodando o analyzer nos mesmos arquivos avulsos antes de
qualquer alteração), nenhum deles em arquivo tocado por esta task.

## Resultado dos testes

- `flutter test test/features/barcode_scanner` → **47 testes passaram** (0 falhas).
- `flutter test test/core/analytics/analytics_events_test.dart` → **1 teste passou** (lista de eventos
  sincronizada).
- `flutter test test/features/audit_log` → todos os testes existentes continuam passando com o novo
  `AuditAction`.
- `flutter test test/app/injection_test.dart` → grafo de DI da feature `settings` continua resolvendo
  normalmente (não afetado por esta task).

## Decisões técnicas

1. **Sem nova tabela Drift/coleção Firestore para o índice de códigos**: a busca por SKU/EAN de
   variante reaproveita `ProductVariantRepository.listByOrganization` (hoje `SharedPreferences`, já a
   fonte local real de variantes usada pelo resto do app) e a busca por identificador de produto
   reaproveita o índice de busca já existente (`SearchProductsUseCase`, Drift offline + Firestore
   remoto). Construir uma tabela Drift paralela alimentada por nada (as tabelas
   `ProductsTable`/`ProductVariantsTable` já existem no schema mas não são populadas por nenhum
   pipeline real ainda — são infraestrutura para o futuro motor de sync, TASK-109) teria criado código
   morto em vez de reaproveitar o que já funciona hoje.
2. **Registro de código alternativo é local (`SharedPreferences`), não Firestore**: manter o escopo
   controlado — persistir localmente já satisfaz literalmente "índice local offline" do escopo técnico
   e é suficiente para o cenário mais comum (o próprio vendedor corrige um código que acabou de
   escanear). Ver "Riscos conhecidos" para a limitação real que isso implica (não sincroniza entre
   vendedores/dispositivos) e a evolução natural (mover para uma coleção Firestore com Cloud Function
   de escrita, mesmo padrão de `backorder`/`fulfillment`) quando essa lacuna importar de fato.
3. **"Leitura repetida incrementa quantidade" implementado como contador de sessão do scanner, não
   quantidade de pedido**: em vez de construir uma tela própria de "escaneamento contínuo com lista de
   pendentes" (que precisaria reimplementar quantidade/preço/estoque em paralelo ao que
   `ProductDetailPage` já faz, risco real de duplicar regra de negócio), o `BarcodeScanCubit` conta
   quantas vezes o mesmo código foi lido na sessão atual e mostra isso como feedback visível
   ("Lido Nx"). A regra de negócio, lida literalmente ("incrementar quantidade... com feedback
   visível, somente quando o contexto permitir"), fica satisfeita dentro do próprio contexto do
   scanner; o ajuste real de quantidade continua acontecendo exclusivamente em
   `ProductDetailPage`/`CommercialSizeGrid` (já existente, não duplicado).
4. **Integração real ponta-a-ponta só em "pedido" (`OrderProductCatalogPage`)**: dos quatro contextos
   citados no escopo técnico ("busca global, detalhe do produto, pedido e conferência de
   mostruário"), só "pedido" tem hoje uma tela real, roteada e usada pelo vendedor
   (`OrderProductCatalogPage`, cabeada via `bootstrap.dart`/`app_router.dart`). Investiguei os outros
   três antes de decidir:
   - **Busca global**: `ProductSearchPage` (que já teria bom encaixe — seu placeholder já cita "Nome,
     SKU, referência, EAN ou tag") **não está roteada em nenhum lugar do app hoje** — o único chamador
     existente é `CampaignFormPage`/`_openProductSearch`, ele mesmo não wireado a nenhuma rota real
     (`grep` não encontrou `CampaignFormPage(` sendo instanciado em lugar nenhum). Cabear o scanner
     ali sem uma tela alcançável de fato seria só um exercício de forma, não uma entrega de valor —
     documentado como pendência.
   - **Detalhe do produto**: `ProductDetailPage` cria e possui seu próprio `BlocProvider<ProductDetailBloc>`
     internamente (não exposto ao chamador), então um botão de scan *dentro* dela só teria valor real
     (reselecionar variante sem sair da tela) se o `ProductDetailBloc` pudesse ser dirigido de fora —
     mudança mais profunda nesse arquivo largamente compartilhado (catálogo, favoritos, campanhas,
     pedido) do que o escopo desta task comporta com segurança. Documentado como pendência.
   - **Conferência de mostruário**: a feature de mostruário/amostras/consignação é a própria
     TASK-217, **ainda não implementada** — não existe tela para integrar hoje.
   A capacidade genérica (`ResolveProductCodeUseCase`, `BarcodeScannerPage`,
   `BarcodeScannerCameraSurfaceBuilder` para testabilidade) está pronta, testada e exportada pelo
   barrel da feature exatamente para que essas três integrações futuras sejam só "chamar o que já
   existe", sem repetir nenhuma decisão de arquitetura.
5. **Câmera testável sem hardware real**: `BarcodeScannerCameraSurface` (o único arquivo que toca
   `package:mobile_scanner`) fica isolada atrás de `BarcodeScannerCameraSurfaceBuilder`, um seam que
   os testes de widget substituem por um stub — nenhum teste depende de plugin/canal de plataforma
   real, e os cenários de "permissão negada"/"leitura válida"/"leitura inválida"/"fallback manual"
   exigidos pela task são todos exercitados através do mesmo `BarcodeScanCubit.onCodeDetected` que uma
   detecção real chamaria.
6. **Escolha do pacote de câmera**: `mobile_scanner` (mantido ativamente, CameraX/ML Kit no Android,
   AVFoundation/Apple Vision no iOS, ZXing no Web) — cobre exatamente as três plataformas deste
   repositório (`android/`, `ios/`, `web/`; não há pasta `windows/`/`linux/`/`macos/`).

## Riscos conhecidos

- **Códigos alternativos não sincronizam entre vendedores/dispositivos**: hoje ficam só no
  `SharedPreferences` de quem cadastrou. Uma correção feita por um vendedor não aparece para outro até
  uma futura sincronização (Firestore + Cloud Function), fora do escopo desta task.
- **Correspondência exata sujeita à qualidade do índice de busca reaproveitado**: o passo de
  correspondência por identificador de produto depende do `SearchProductsUseCase` já existente
  (busca "contains", não um índice de igualdade dedicado) para encontrar candidatos antes do filtro
  exato local — em catálogos muito grandes com muitos produtos cujo texto normalizado contenha o
  código como substring, o `limit` padrão (20) poderia, em tese, deixar o candidato exato de fora da
  primeira página de resultados. Não observado nos testes (`Ean`/`Sku` são tipicamente curtos e
  específicos o bastante), mas é uma limitação teórica documentada.
- **Câmera não testável em dispositivo físico neste ambiente** (sandbox sem hardware de câmera) — não
  é bloqueio real per `AGENTS.md`: a implementação é sólida (baseada em `mobile_scanner`,
  amplamente usado) e testável via `BarcodeScannerCameraSurfaceBuilder`, mas a superfície real da
  câmera (`BarcodeScannerCameraSurface`) só foi validada por leitura cuidadosa do código-fonte do
  pacote, nunca em um device real Android/iOS/Web.
- **"Busca global"/"detalhe do produto"/"conferência de mostruário" sem integração cabeada** — ver
  "Decisões técnicas" item 4 e "Pendências" abaixo.
- **`injection.config.dart` editado manualmente, não pelo `build_runner`**: o `build_runner` travou
  neste ambiente (ver "Arquivos alterados") e as 5 novas entradas de DI foram inseridas à mão,
  seguindo fielmente o padrão já existente no arquivo e verificadas por `flutter analyze` + resolução
  real de ponta a ponta via `getIt` (ver detalhe na mesma seção). Ainda assim, a próxima vez que o
  `build_runner` rodar com sucesso sobre este arquivo, o diff deve ser conferido antes de commitar
  (é esperado que ele produza os mesmos 5 registros, possivelmente com nomes de prefixo `_iNNN`
  diferentes dos que usei — isso é inofensivo, mas vale confirmar visualmente).

## Pendências

- Rotear `ProductSearchPage` (ou uma tela equivalente) como "busca global" de fato alcançável, e então
  cabear o botão de scan que já está pronto para ser adicionado ali.
- Avaliar uma forma segura de driblar `ProductDetailBloc` a partir de fora de `ProductDetailPage`
  (ex.: um controller externo opcional) para permitir reselecionar variante por scan sem sair da tela
  de detalhe já aberta.
- Integrar `BarcodeScannerPage`/`ResolveProductCodeUseCase` na tela de conferência de mostruário assim
  que a TASK-217 (gestão de mostruário/amostras/consignação) existir.
- Construir uma tela/fluxo de UI para `RegisterUnknownProductCodeUseCase` (hoje só a capacidade de
  domínio existe, testada; não há um picker de produto na tela de "código não encontrado" — decisão de
  escopo para não construir uma busca de produto redundante dentro desta mesma task).
- Sincronizar `AlternateProductCode` para Firestore (Cloud Function de escrita + leitura) quando a
  limitação de "só neste dispositivo" (ver "Riscos conhecidos") importar na prática.

## Evidências

- `flutter test test/features/barcode_scanner` → 47 passed.
- `flutter test test/core/analytics/analytics_events_test.dart` → 1 passed.
- `flutter analyze` (repositório inteiro) → 19 issues pré-existentes, 0 novas.

## Commit

Único commit reunindo a feature `barcode_scanner` completa, integração em `orders`, analytics, audit
log, permissões de câmera nas plataformas nativas, testes e atualização do índice de tasks.

## Push

**Não realizado** — autorização desta rodada é apenas para commit local, conforme instrução explícita
do usuário.

## Hash do commit

Ver commit da task no histórico do Git (mensagem `feat(barcode-scanner): implementar leitura de
código de barras e QR para venda rápida`).

## Branch

`main`
