# TASK-179 — Concluída (2026-09-07)

## Resumo

Implementado o catálogo white-label (EPIC-25): uma organização pode configurar logo e cor
principal do catálogo exibido a clientes finais, e essa marca é aplicada — **sem nenhuma
duplicação de código de catálogo** — sobre os mesmos componentes de catálogo já existentes
(`AppProductGrid`/`AppProductCard`, Design System desde TASK-024) e sobre a mesma montagem de
`ThemeData` que `AppTheme.light`/`AppTheme.dark` já usam (TASK-020).

A configuração de marca reaproveita o par `OrganizationSettings.brandingLogoUrl`/
`brandingPrimaryColorHex` já modelado desde a TASK-148 (branding de PDF) — nenhum novo modelo de
dados foi criado. O que faltava, e é o que esta task entrega: (1) uma camada de tema do Design
System que deriva um `AppColors`/`ThemeData` por organização com fallback automático de contraste
(`AppBrandTheme`), (2) o fechamento do caminho de escrita dessa configuração (o use case existente
nunca expunha esses dois campos, então nenhuma tela jamais conseguia realmente salvá-los), (3) a
aplicação real do tema nas superfícies voltadas ao cliente final — o link de compartilhamento de
catálogo público (`CatalogSharePublicPage`, TASK-081) — e (4) a tela de configuração de marca no
portal admin, com pré-visualização em tempo real reaproveitando o próprio `AppProductGrid`.

O portal B2B do cliente final (TASK-182) ainda não existe; quando for implementado, deve
simplesmente consumir o mesmo `AppBrandTheme`/mesma configuração de `OrganizationSettings`, sem
recriar nenhuma peça desta task.

## Agentes utilizados

- `flutter-ui-design-specialist` (Design System: `AppContrast`, `AppBrandTheme`, refatoração de
  `AppTheme` para expor `fromColors`, tela `BrandingSettingsPage` com pré-visualização em tempo
  real, aplicação do tema/logo em `CatalogSharePublicPage`).
- `flutter-senior-architect` (extensão do `UpdateOrganizationSettingsUseCase`, `BrandingSettingsCubit`
  seguindo Clean Architecture + BLoC, extensão do Cloud Function `getCatalogShareLink` e do DTO/
  mapper/entidade de `CatalogSharePreview` para transportar a marca da organização até o visitante
  anônimo sem vazar `organizationId`).

## Arquivos criados

Design System (`lib/core/design_system`):
- `foundations/app_contrast.dart` — utilitário de contraste WCAG 2.x (`AppContrast.ratio`/
  `meetsWcagAa`/`relativeLuminance`), extraído para ser compartilhado entre produção e teste.
- `theme/app_brand_theme.dart` — `AppBrandTheme.resolveColors`/`needsContrastFallback`/
  `resolveTheme`: deriva um `AppColors`/`ThemeData` por organização a partir de um hex de cor
  primária, sempre reaproveitando `AppTheme.fromColors`.

Organizations (`lib/features/organizations/presentation`, primeira camada de apresentação desta
feature):
- `cubit/branding_settings_state.dart`, `cubit/branding_settings_cubit.dart`
- `pages/branding_settings_page.dart` (inclui `_BrandedCatalogPreview`, que reaproveita
  `AppProductGrid` para a pré-visualização em tempo real)

Testes novos:
- `test/core/design_system/foundations/app_contrast_test.dart`
- `test/core/design_system/theme/app_brand_theme_test.dart`
- `test/features/organizations/presentation/cubit/branding_settings_cubit_test.dart`
- `test/features/organizations/presentation/pages/branding_settings_page_test.dart`

## Arquivos alterados

Cloud Functions (`functions/src/catalog`):
- `catalog-share-shared.ts`: `CatalogSharePreviewResponse`/`serializeCatalogSharePreview` passam a
  incluir `brandingLogoUrl`/`brandingPrimaryColorHex` (parâmetro `branding`, opcional, default
  `null`/`null` — aditivo, não quebra nenhum chamador existente).
- `get-catalog-share-link.ts`: lê `organizations/{organizationId}.settings.brandingLogoUrl`/
  `brandingPrimaryColorHex` (já existentes desde TASK-148) e repassa ao preview público —
  server-side, então o visitante anônimo nunca precisa conhecer o `organizationId` para receber a
  marca; `null`/`null` em todo outcome que não seja `valid` (mesma regra de "nunca vaza dado de
  link expirado/revogado/inexistente" que já existia).
- `functions/test/catalog/get-catalog-share-link.test.ts`: 3 novos testes (marca presente, marca
  ausente, marca nunca vaza para outcome revogado); helper `seedOrganization` ganhou parâmetro
  opcional `settingsOverrides`.

Design System (`lib/core/design_system`):
- `theme/app_theme.dart`: `_build` (privado) virou `fromColors` (público) — mesma implementação,
  agora reutilizável por `AppBrandTheme.resolveTheme` sem duplicar a montagem do `ThemeData`.
- `theme/theme.dart`, `foundations/foundations.dart`: barrels atualizados com os 2 arquivos novos.

Catálogo compartilhado (`lib/features/catalog_share`):
- `domain/entities/catalog_share_preview.dart` (+ `.freezed.dart`, regenerado): novos campos
  opcionais `brandingLogoUrl`/`brandingPrimaryColorHex`.
- `data/dtos/catalog_share_preview_dto.dart`: parse dos 2 novos campos (`null` quando ausentes).
- `data/mappers/catalog_share_mapper.dart`: `previewToEntity` repassa os 2 novos campos.
- `presentation/pages/catalog_share_public_page.dart`: `_CatalogSharePublicView` agora envolve o
  `Scaffold` num `Theme` derivado por `AppBrandTheme.resolveTheme(primaryColorHex: state.preview
  ?.brandingPrimaryColorHex)`; `_ValidView` renderiza o logo da organização (`_BrandLogo`, novo
  widget privado) quando configurado, sempre com altura fixa reservada e fallback silencioso (sem
  ícone de "imagem quebrada") para não parecer um bug do app.

Organizations (`lib/features/organizations`):
- `domain/usecases/update_organization_settings_use_case.dart`: novos parâmetros opcionais
  `brandingLogoUrl`/`brandingPrimaryColorHex`, repassados a `OrganizationSettings.validated` — o
  modelo já suportava esses campos desde TASK-148, mas nenhum use case os expunha; sem esta
  extensão não havia caminho algum, em nenhuma tela, para efetivamente salvar uma marca.
- `organizations.dart`: barrel passa a exportar também a camada de apresentação nova (mesmo
  precedente de `targets.dart`).

Analytics:
- `lib/core/analytics/analytics_events.dart`: novo evento `catalogBrandingUpdated`
  (`catalog_branding_updated`), disparado ao salvar a configuração de marca.

Regressão (contraste, sem duplicar lógica):
- `test/core/design_system/foundations/app_colors_test.dart`: os cálculos de luminância/contraste
  duplicados localmente (`_relativeLuminance`/`_contrastRatio`/`_wcagAaNormalText`) foram
  substituídos por `AppContrast` (mesma implementação agora também usada em produção).
- `test/core/design_system/theme/app_theme_test.dart`: 2 novos testes cobrindo `AppTheme
  .fromColors` (mesma montagem de `light`/`dark`, aplica um `AppColors` arbitrário).

DI/geração (build_runner):
- `lib/app/injection.config.dart`: registro de `BrandingSettingsCubit` (`@injectable`).

## Arquitetura utilizada

Clean Architecture feature-first + BLoC, consistente com o restante do projeto:

- `BrandingSettingsPage` (UI) → `BrandingSettingsCubit` → `GetOrganizationUseCase`/
  `UpdateOrganizationSettingsUseCase` (já existentes) → `OrganizationRepository` (contrato já
  existente) — nenhum novo caminho de escrita de `Organization` foi criado, mesmo precedente já
  estabelecido por `PositivacaoSettingsCubit` (TASK-117): o cubit reenvia toda a
  `OrganizationSettings` existente junto com os campos de marca editados, porque
  `FirestoreOrganizationDataSource.updateSettings` substitui o mapa `settings` inteiro (nunca faz
  merge parcial).
- `AppBrandTheme` vive inteiramente no Design System (`lib/core/design_system/theme`), sem
  importar nada de `organizations`/`catalog_share` — é uma função pura de tema (hex → `AppColors`/
  `ThemeData`), a mesma característica de "Design System não conhece features" que toda a camada
  de foundations já respeitava desde TASK-020.
- `CatalogSharePublicPage` (UI) continua não acessando Firestore/Storage diretamente: a marca
  chega já resolvida no `CatalogSharePreview` (entidade de domínio), populada pelo mesmo
  `CatalogShareLookupRepository`/`PreviewCatalogShareUseCase` (TASK-081) que já existia — nenhuma
  nova dependência foi introduzida na UI.
- Regra de negócio (validação de formato do hex `#RRGGBB`, fallback de contraste) não vive em
  widget algum: o formato é validado por `OrganizationSettings.validated` (já existente, TASK-148)
  e o fallback de contraste vive em `AppBrandTheme` (Design System, testável isoladamente).

## Regras de negócio implementadas

- Nenhuma tela de catálogo tem versão de código duplicada por organização: a única diferença
  visual entre organizações é o `ThemeData` resolvido por `AppBrandTheme.resolveTheme`, aplicado
  via `Theme` sobre a mesma árvore de widgets (`AppProductGrid`/`AppProductCard`).
- Contraste mínimo de acessibilidade (WCAG AA, >= 4.5:1) nunca é reduzido por uma cor customizada:
  `AppBrandTheme.resolveColors` só aplica a cor primária customizada com um `onPrimary` (cor de
  texto sobreposto) que atinja WCAG AA — testando primeiro a cor de texto padrão do tema, depois
  branco, depois preto — nunca ficando com um par ilegível.
- Uma cor mal formatada (`primaryColorHex` que não bate com `^#[0-9A-Fa-f]{6}$`) é descartada
  inteiramente: o catálogo volta a usar a paleta padrão do Design System, nunca quebra/lança
  exceção.
- Configuração de marca pertence exclusivamente à organização que a definiu: vive dentro do
  próprio documento `organizations/{organizationId}.settings`, já isolado por tenant desde
  TASK-026/037; o visitante anônimo do link de catálogo nunca recebe o `organizationId`, apenas a
  marca (logo/cor) já resolvida.
- Alterar a marca não altera nenhuma regra de disponibilidade/preço/permissão do catálogo: é
  puramente uma camada visual (`Theme`), nunca uma branch de dado/regra.
- Tela de configuração de marca é sempre gated por `Capability.organizationSettingsManage` (mesma
  capability que já protege currency/positivação/ranking desde TASK-027/117/118) — só OWNER/ADMIN
  vê/edita.

## Regras Firebase implementadas

Nenhuma regra nova de `firestore.rules`: a marca (`brandingLogoUrl`/`brandingPrimaryColorHex`) já
vive dentro de `organizations/{organizationId}.settings`, cujo `update` já exige
`hasCapability(organizationId, 'organization.settingsManage')` desde antes desta task (linha 725
de `firestore.rules`, inalterada). A leitura server-side em `getCatalogShareLink` usa o Admin SDK
(Cloud Function), que ignora as Rules do cliente — mesmo padrão que TASK-081 já usa para
`organizationName`; o visitante nunca lê `organizations/{organizationId}` diretamente.

## Analytics implementado

- `catalog_branding_updated`: disparado por `BrandingSettingsCubit.submit` ao salvar a
  configuração com sucesso, com `organization_id`.

## Crashlytics implementado

Nenhuma instrumentação nova além do fluxo central já existente: toda falha de repositório/
Cloud Function já converte para `Failure`/`AppException` pelo mapeamento central; nenhum `print`
ou exceção não tratada foi introduzido.

## Impacto offline

A leitura/edição da configuração de marca (`BrandingSettingsCubit`) depende de rede, como todo o
resto de `OrganizationSettings` (mesma limitação já aceita por `PositivacaoSettingsCubit`/TASK-117
— não é uma regressão). A resolução do tema em si (`AppBrandTheme`) é uma função pura, sem I/O:
uma vez que a marca chegou (via `Organization` carregada ou via preview de compartilhamento já
resolvido), aplicar o tema não depende de conectividade.

## Impacto multi-tenant

A marca vive dentro do documento da própria organização (`organizations/{organizationId}
.settings`), nunca em uma coleção compartilhada. `AppBrandTheme` é uma função pura sem estado —
não existe cache global que pudesse vazar a cor/logo de uma organização para outra; cada chamada
recebe explicitamente o hex/URL já resolvido para aquela organização. No link de compartilhamento
público, o visitante nunca aprende o `organizationId` real, apenas a marca já resolvida
server-side para aquele link especificamente (mesma garantia de isolamento que TASK-081 já
documentou para `organizationName`).

## Testes criados

- **`AppContrast`** (`test/core/design_system/foundations/app_contrast_test.dart`): ratio entre
  cores idênticas/opostas, simetria, `meetsWcagAa` verdadeiro/falso, `relativeLuminance`.
- **`AppBrandTheme`** (`test/core/design_system/theme/app_brand_theme_test.dart`):
  `resolveColors` (hex nulo/em branco/malformado retorna base inalterada; cor válida escura mantém
  o `onPrimary` padrão; cor válida clara troca o `onPrimary` para permanecer legível; isolamento
  entre duas resoluções não vaza uma cor na outra); `needsContrastFallback` (falso quando não
  configurado ou aplicado sem ajuste; verdadeiro para hex malformado ou quando o texto precisou
  trocar); `resolveTheme` (aplica a cor customizada; cai no fallback padrão para hex malformado;
  é a mesma montagem de `AppTheme.fromColors`, nunca uma árvore duplicada).
- **`AppTheme`** (`test/core/design_system/theme/app_theme_test.dart`, 2 testes novos):
  `fromColors` é exatamente a montagem que `light`/`dark` usam; aplica um `AppColors` arbitrário.
- **`UpdateOrganizationSettingsUseCase`** (teste existente estendido): passa a marca através para
  o repositório; rejeita com `ValidationFailure` (`fieldErrors['brandingPrimaryColorHex']`) uma
  cor malformada sem nunca chamar o repositório.
- **`BrandingSettingsCubit`** (7 testes novos): carrega os campos de marca já configurados;
  campos vazios quando nada configurado; falha de carregamento; `usesContrastFallback` reativo à
  digitação; `submit` reenviando toda a configuração existente + evento de analytics; `submit`
  limpando a marca quando os campos ficam em branco; erro de campo para hex malformado, sem
  disparar analytics.
- **`BrandingSettingsPage`** (5 testes de widget): tela proibida (`ForbiddenPage`) para quem não
  tem a capability; carrega e renderiza a configuração atual (com o preview já com a cor aplicada,
  reaproveitando `AppProductGrid`); pré-visualização atualiza em tempo real ao digitar; aviso de
  fallback de contraste aparece para cor de baixo contraste; salvar mostra snackbar de sucesso e
  chama o repositório com a configuração completa.
- **`CatalogSharePreviewDto`/`CatalogShareMapper`** (testes existentes estendidos): parse e
  mapeamento dos 2 novos campos, com default `null` quando ausentes.
- **`CatalogSharePublicPage`** (5 testes de widget novos): aplica a cor de marca sobre o `Theme`
  real do catálogo; cai no tema padrão para uma cor malformada sem quebrar a tela; renderiza o
  logo quando configurado; não renderiza nenhuma caixa de logo quando não configurado; duas
  organizações diferentes (via dois links distintos) nunca compartilham a mesma marca resolvida.
- **Cloud Functions** (`functions/test/catalog/get-catalog-share-link.test.ts`, 3 testes novos):
  marca configurada é repassada ao preview válido; ausência de marca retorna `null`/`null`; marca
  nunca vaza para um link revogado.

## Comandos executados

```bash
dart run build_runner build
dart format lib test functions/src functions/test
dart format --set-exit-if-changed <arquivos desta task>
flutter analyze
flutter test test/core/design_system test/features/organizations test/features/catalog_share
flutter test
npm --prefix functions run build
npm --prefix functions run lint
```

## Resultado do formatter

`dart format --set-exit-if-changed` restrito aos 25 arquivos desta task: `Formatted 25 files (0
changed)` — sem diferenças pendentes. (A primeira chamada de `dart format` sem escopo restrito
também reformatou 3 arquivos de outras tasks, já formatados de forma diferente da versão atual do
`dart format` — revertidos com `git checkout --` por estarem fora do escopo desta task.)

## Resultado do analyzer

`flutter analyze` (projeto completo): `15 issues found` — todos pré-existentes, em arquivos não
tocados por esta task (`customer_import`/`product_import`/`reports`/testes de `dashboards`), nada
relacionado a TASK-179.

## Resultado dos testes

- `flutter test test/core/design_system test/features/organizations test/features/catalog_share`:
  `+592, All tests passed!`.
- `flutter test` (suíte completa do projeto): `+3120 -2`. As 2 falhas são **pré-existentes**,
  confirmadas via `git stash`/`git stash pop` contra o baseline sem as mudanças desta task:
  - `test/core/analytics/analytics_events_test.dart`: a lista fixa do teste já estava
    desatualizada antes desta task (parava em `crm_reminder_triggered`, faltando eventos já
    adicionados por TASK-152+ como `commercial_order_alert_triggered`/
    `communication_preferences_updated`/`app_locale_changed`) — meu novo evento
    `catalog_branding_updated` apenas se soma a uma lista já divergente, não é a causa raiz.
  - `test/app/bootstrap_test.dart`: `GetIt: Object/factory with type PushDeviceMapper is not
    registered` — `PushDeviceMapper` (`lib/core/notifications/data/mappers/push_device_mapper.dart`)
    nunca teve anotação `@injectable`/`@lazySingleton`, uma lacuna de DI pré-existente e alheia a
    esta task (feature `notifications`, não tocada aqui).
- `npm --prefix functions run build` (tsc): sem erros.
- `npm --prefix functions run lint` (eslint): sem erros.

## Decisões técnicas

- **Reaproveitar `OrganizationSettings.brandingLogoUrl`/`brandingPrimaryColorHex` (TASK-148) em
  vez de criar um novo `BrandingConfig`.** O modelo já existia, já validado (`#RRGGBB`), já isolado
  por tenant — criar um segundo modelo paralelo violaria a regra "não duplicar" do `AGENTS.md` sem
  agregar nada. O gap real (o motivo desta task ainda ser necessária) era a ausência de qualquer
  caminho de escrita/UI/aplicação visual desses dois campos — não a ausência do modelo.
- **Apenas cor primária, não "primária/secundária" como o texto da task sugeria.** O modelo
  existente desde TASK-148 só tem `brandingPrimaryColorHex` (nenhum campo de cor secundária foi
  modelado até hoje). Adicionar um `brandingSecondaryColorHex` novo exigiria estender
  `OrganizationSettings`/DTO/mapper por um campo sem nenhum consumidor real ainda — registrado como
  pendência explícita, não implementado especulativamente.
- **`AppBrandTheme` nunca reverte inteiramente para a paleta padrão quando o hex é válido** —
  mesmo quando o texto precisa trocar de branco/preto para caber no contraste, a cor primária
  customizada continua sendo aplicada (só o texto sobreposto muda). Só um hex malformado descarta
  a cor inteiramente. Matematicamente, para qualquer cor de fundo, pelo menos um entre
  branco/preto sempre atinge WCAG AA 4.5:1 (as faixas de contraste se sobrepõem em toda a escala
  de luminância) — então "a cor não atinge contraste com nenhum candidato" nunca acontece de fato
  para uma cor válida; o "fallback" real e observável é sempre a troca do texto, nunca da cor.
- **`needsContrastFallback` (usado para o aviso na tela de admin) é calculado apenas contra
  `AppColors.light`**, não contra os dois temas. A mesma cor pode precisar de um texto diferente
  no tema escuro vs. claro (o texto padrão de cada tema é diferente); como a superfície
  cliente-final hoje implementada (`CatalogSharePublicPage`) e a própria pré-visualização da tela
  de admin usam o tema claro como referência visual, calcular against os dois temas gerava avisos
  para cores que na prática funcionam perfeitamente na superfície que o admin está vendo — uma
  falsa fricção, não uma proteção real.
- **Logo renderizado com `CachedNetworkImage` (já dependência do projeto, mesmo padrão de
  `AppProductGrid`), nunca `Image.network` cru** — mesmo comportamento de cache/decodificação já
  estabelecido; `errorWidget`/`placeholder` retornam uma caixa vazia de altura fixa (nunca um
  ícone de "imagem quebrada"), para que uma URL de logo mal configurada nunca pareça um bug do
  aplicativo para o cliente final.
- **`BrandingSettingsCubit`/`Page` não foram conectados ao `AppRouter`** — mesmo precedente já
  registrado por `PositivacaoSettingsFormPage` (TASK-117): a tela existe, testada, injetável via
  DI, mas nenhuma rota de shell/admin foi criada para alcançá-la; fica como pendência explícita,
  não uma omissão silenciosa.
- **Pré-visualização usa produtos de exemplo estáticos (`sample-1..3`)**, nunca um produto real do
  catálogo da organização — evita qualquer necessidade de rede/Firestore na própria tela de
  configuração de marca (que já teria RBAC + Firestore reais só para a organização) e mantém a
  tela funcionando mesmo para uma organização sem nenhum produto cadastrado ainda.

## Riscos conhecidos

- `brandingSecondaryColorHex` não existe — se um requisito futuro realmente precisar de uma
  segunda cor de marca, será uma extensão aditiva de `OrganizationSettings` (mesmo padrão desta
  task), não uma reformulação.
- Contraste é validado só contra `AppColors.light` na tela de admin (ver "Decisões técnicas") — um
  tema escuro do catálogo público (hoje `CatalogSharePublicPage` segue `Theme.of(context)
  .brightness` do dispositivo do visitante) pode, em teoria, exigir um ajuste de texto diferente
  do que a pré-visualização do admin mostra; `AppBrandTheme.resolveTheme` já lida com isso
  corretamente em tempo de execução (recalcula o fallback para o brightness real), então não há
  risco de acessibilidade — apenas o aviso na tela de admin pode não cobrir 100% dos casos do tema
  escuro.
- `test/core/analytics/analytics_events_test.dart` e `test/app/bootstrap_test.dart` continuam
  falhando na suíte completa por motivos pré-existentes e não relacionados a esta task (ver
  "Resultado dos testes") — não corrigidos aqui por estarem fora do escopo de TASK-179.

## Pendências

- Integração de `BrandingSettingsPage` ao `AppRouter`/shell administrativo (mesma pendência já
  registrada por `PositivacaoSettingsFormPage`, TASK-117).
- Aplicar `AppBrandTheme` ao futuro portal B2B do cliente (TASK-182, ainda não implementado) —
  quando essa task existir, deve consumir a mesma `OrganizationSettings.brandingLogoUrl`/
  `brandingPrimaryColorHex` e o mesmo `AppBrandTheme`, sem recriar nada desta task.
- `brandingSecondaryColorHex`/paleta secundária (ver "Decisões técnicas").
- Corrigir `test/core/analytics/analytics_events_test.dart` (lista desatualizada desde antes desta
  task) e a lacuna de DI de `PushDeviceMapper` (`test/app/bootstrap_test.dart`) — ambos
  pré-existentes, fora do escopo desta task isolada.

## Evidências

- `flutter test test/core/design_system test/features/organizations test/features/catalog_share`:
  `+592, All tests passed!`.
- `flutter test` (suíte completa): `+3120 -2` — as 2 falhas são pré-existentes (ver "Resultado dos
  testes"/"Riscos conhecidos").
- `flutter analyze`: `15 issues found`, todos pré-existentes e alheios a esta task.
- `dart format --set-exit-if-changed` (arquivos desta task): sem diferenças.
- `npm --prefix functions run build`/`lint`: sem erros.

## Commit

Ver seção "Commit" da resposta final — mensagem/hash reais do `git commit`, nunca inventados.

## Push

Não realizado nesta rodada (não autorizado).

## Hash do commit

Ver seção "Commit" da resposta final — hash real do `git commit`, nunca inventado.

## Branch

main
