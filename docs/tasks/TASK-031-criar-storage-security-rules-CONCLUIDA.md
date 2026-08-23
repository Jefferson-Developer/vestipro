# TASK-031 — Concluída (2026-08-23)

## Resumo

Implementadas as Firebase Storage Security Rules reais para os 3 tipos de mídia hoje modelados em
`lib/core/storage/storage_paths.dart` (TASK-014): fotos de produto, anexos de pedido e avatar de
usuário. O placeholder "deny all" (introduzido na TASK-010) foi substituído por regras que exigem um
Membership real e ativo do usuário autenticado — relido diretamente do Firestore via Cross-Service
Security Rules (`firestore.get`/`firestore.exists`), nunca a partir do path ou de qualquer metadado
do próprio arquivo — e que validam tipo de conteúdo e tamanho máximo no próprio upload, não apenas na
UI. RBAC (TASK-029) é espelhado em `storage.rules` por uma função `roleHasCapability` idêntica à já
existente em `firestore.rules` (TASK-030). Foi criada a infraestrutura de testes de rules
(`storage-tests/`, com `@firebase/rules-unit-testing` + `firebase` (SDK modular) + Jest) e 28 testes
positivos/negativos (incluindo cross-tenant explícito, tipo de arquivo inválido, tamanho excedido,
Membership inativo e exclusão administrativa) foram escritos e executados com sucesso no Firebase
Emulator Suite (Firestore + Storage).

## Agentes utilizados

- `flutter-senior-architect` (único exigido pela task).

## Arquivos criados

- `storage-tests/package.json` — dependências (`@firebase/rules-unit-testing`, `firebase`, `jest`) e
  script `npm test` para o pacote de testes de Storage rules.
- `storage-tests/storage.rules.test.js` — 28 testes positivos/negativos contra o Storage Emulator
  real (com o Firestore Emulator rodando junto, para as chamadas cross-service), cobrindo os 3 paths
  de mídia (produto, anexo de pedido, avatar) e o deny-by-default de qualquer path não modelado.
- `docs/tasks/TASK-031-criar-storage-security-rules-CONCLUIDA.md` — este arquivo.

## Arquivos alterados

- `storage.rules` — substituído o placeholder "deny all" pelas regras reais descritas abaixo.
- `.gitignore` — adicionado `/storage-tests/node_modules/` (mesmo padrão já usado para
  `/firestore-tests/node_modules/` e `/functions/node_modules/`).
- `lib/core/storage/storage_paths.dart` — doc comment atualizado: não referencia mais `storage.rules`
  como "deny-all today, real RBAC lands in TASK-031" (já implementado).
- `integration_test/core/storage/firebase_storage_data_source_integration_test.dart` — doc comment
  atualizado para explicar que o teste continua validando um caminho de negação, mas agora pela razão
  real (`request.auth == null` falha `isActiveMember`), não mais pelo placeholder deny-all.
- `README.md` — seção "Backend e Firebase": `firestore.rules`/`storage.rules` já implementam RBAC e
  isolamento multi-tenant real, com testes em `firestore-tests/`/`storage-tests/`.
- `docs/tasks/TASKS.md` — checkbox da TASK-031 marcado e `Progresso` atualizado para `31 / 220`.

## Arquitetura utilizada

N/A para código Dart novo (task é 100% Firebase Storage Rules + testes JS). As duas alterações Dart
são apenas atualização de comentário (doc comment), sem mudança de comportamento/API — confirmado por
`flutter analyze`/`flutter test` sem regressão. Os paths e limites de tipo/tamanho usados nas regras
foram conferidos diretamente contra `StoragePaths` (TASK-014) e contra o RBAC real
(`lib/core/permissions/capability.dart`/`role_permission_matrix.dart`, TASK-029), garantindo que a
regra reflita exatamente o que o app já constrói/pretende gravar.

## Regras de negócio implementadas

- `isActiveMember(organizationId)`: reaproveita a mesma decisão de `firestore.rules` (TASK-030), mas
  via Cross-Service Security Rules (`firestore.exists`/`firestore.get` contra
  `/databases/(default)/documents/organizations/{organizationId}/members/{request.auth.uid}`) — nunca
  confia em nenhum campo do path/metadado do arquivo de Storage sendo lido/escrito.
- `roleHasCapability(roleName, capabilityCode)`/`hasCapability(organizationId, capabilityCode)`:
  cópia funcional exata do que já existe em `firestore.rules`, terceira cópia manual da mesma tabela
  (a primeira é `RolePermissionMatrix`, a segunda é `firestore.rules`) — ver "Riscos conhecidos".
- Fotos de produto (`organizations/{organizationId}/products/{productId}/{fileName}`): leitura para
  qualquer membro ativo da organização; criação/atualização exige `catalog.manage` (só OWNER/ADMIN na
  matriz atual) + `contentType` iniciando em `image/` + tamanho máximo de 10 MB; exclusão é sempre
  administrativa e usa a mesma capability `catalog.manage` (ex.: remover foto enviada por outro
  usuário).
- Anexos de pedido (`organizations/{organizationId}/orders/{orderId}/attachments/{fileName}`): leitura
  para qualquer membro ativo; criação/atualização exige `order.create` (OWNER/ADMIN/SALES_MANAGER/
  SALES_REP) + tipo de conteúdo em uma lista fechada (`application/pdf`, `image/jpeg`, `image/png`,
  `image/webp`, `application/msword`, `.docx`, `.xls`, `.xlsx`) + tamanho máximo de 20 MB; exclusão
  usa a mesma capability `order.create`.
- Avatar de usuário (`organizations/{organizationId}/users/{userId}/avatar`): leitura para qualquer
  membro ativo da organização (ex.: exibir foto em uma listagem de equipe); criação/atualização/
  exclusão exigem que `userId` seja exatamente `request.auth.uid` (nenhuma capability de RBAC — é
  sempre uma ação sobre o próprio perfil, nunca sobre o de outro usuário) + `contentType` de imagem +
  tamanho máximo de 5 MB no create/update.
- Deny by default: qualquer path fora desses 3 (`match /{allPaths=**} { allow read, write: if false }`)
  é sempre negado — nenhum novo tipo de mídia fica acessível "de graça" só por ter o prefixo
  `organizations/{organizationId}/`.
- Nunca confia no path como prova de pertencimento: um usuário da Org A tentando ler/escrever sob
  `organizations/{orgB}/...` é negado mesmo conhecendo o path exato (testado explicitamente).

## Regras Firebase implementadas

Arquivo `storage.rules` completo (ver arquivo para o texto integral e comentários). Cobertura:

- `organizations/{organizationId}/products/{productId}/{fileName}`: read/create/update/delete
  conforme acima.
- `organizations/{organizationId}/orders/{orderId}/attachments/{fileName}`: read/create/update/delete
  conforme acima.
- `organizations/{organizationId}/users/{userId}/avatar`: read/create/update/delete conforme acima.
- `{allPaths=**}` (catch-all): sempre negado.

`firebase.json` não precisou de alteração (já apontava para `storage.rules`/porta 9199 do emulador
desde a TASK-010, com `"singleProjectMode": true`).

## Analytics implementado

N/A — task não envolve eventos de produto/Analytics.

## Crashlytics implementado

N/A — task não envolve novo código Dart de runtime (só doc comments atualizados).

## Impacto offline

Nenhuma mudança de comportamento offline: Security Rules só atuam nas leituras/escritas que
efetivamente chegam ao Storage. Nenhuma feature usa `StorageDataSource` em produção ainda (só entra
a partir do EPIC-08/TASK-068), então nenhum fluxo de Outbox/sync existente é afetado. O teste de
integração Flutter (`firebase_storage_data_source_integration_test.dart`) continua validando o mesmo
caminho de negação de antes (agora por Membership ausente, não mais pelo placeholder).

## Impacto multi-tenant

Núcleo da task: isolamento cross-tenant de mídia agora é garantido no próprio backend, não apenas por
convenção de path no cliente. Testado explicitamente em `storage-tests/storage.rules.test.js`: um
usuário com Membership só na Org A nunca consegue ler nem escrever nenhum arquivo sob o path da Org B,
mesmo conhecendo o path exato (foto de produto e anexo de pedido testados; avatar testado para
leitura cross-tenant).

## Testes criados

`storage-tests/storage.rules.test.js` — 28 casos com `@firebase/rules-unit-testing` +
`initializeTestEnvironment` (Firestore + Storage juntos) + funções modulares de `firebase/storage`
(`ref`, `uploadBytes`, `getBytes`, `deleteObject`), contra os Emulators reais (não fake/mocked):

- **Fotos de produto**: OWNER (tem `catalog.manage`) envia foto com sucesso; SALES_REP (sem
  `catalog.manage`) é negado; Membership inativo é negado; usuário não autenticado é negado (upload e
  leitura); membro ativo lê foto já existente da própria organização; cross-tenant (Org A não lê/
  escreve sob path da Org B); tipo de arquivo não permitido (executável disfarçado de imagem) é
  rejeitado; tamanho acima de 10 MB é rejeitado; OWNER exclui foto enviada por outro usuário (ação
  administrativa); SALES_REP não exclui (sem capability).
- **Anexos de pedido**: SALES_REP (tem `order.create`) envia anexo com sucesso; SALES_ASSISTANT (sem
  `order.create`) é negado; cross-tenant é negado; usuário não autenticado não lê; membro ativo lê
  anexo já existente; tipo de arquivo não permitido é rejeitado; tamanho acima de 20 MB é rejeitado;
  SALES_MANAGER exclui anexo enviado por outro usuário.
- **Avatar**: usuário envia o próprio avatar com sucesso; usuário não consegue enviar avatar de outro
  usuário; tipo de arquivo não permitido é rejeitado; membro ativo lê avatar de outro membro da mesma
  organização; membro de outra organização não lê (cross-tenant); usuário exclui o próprio avatar;
  usuário não consegue excluir avatar de outro usuário.
- **Deny by default**: um path de mídia ainda não modelado nas rules é sempre negado, mesmo para um
  OWNER autenticado.

## Comandos executados

```bash
cd storage-tests && npm install
export PATH="/c/Program Files/Android/Android Studio/jbr/bin:$PATH"
firebase emulators:exec --only "firestore,storage" "npm --prefix storage-tests test"
firebase emulators:exec --only firestore "npm --prefix firestore-tests test"   # regressão TASK-030
dart format --set-exit-if-changed .
flutter analyze
flutter test
git status --porcelain=v1
```

## Resultado do formatter

`Formatted 380 files (0 changed) in 1.88 seconds.`

## Resultado do analyzer

`No issues found! (ran in 11.0s)`

## Resultado dos testes

`flutter test`: `All tests passed!` (632 testes, nenhuma regressão — só doc comments Dart foram
alterados nesta task).

`firebase emulators:exec --only "firestore,storage" "npm --prefix storage-tests test"`:

```text
Test Suites: 1 passed, 1 total
Tests:       28 passed, 28 total
Snapshots:   0 total
Time:        4.025 s
```

Regressão confirmada em `firestore-tests` (TASK-030), sem alteração de `firestore.rules` nesta task:

```text
Test Suites: 1 passed, 1 total
Tests:       32 passed, 32 total
Snapshots:   0 total
Time:        3.358 s
```

Observação de ambiente: igual à TASK-030, `java -version` não resolve nesta máquina (sem JDK
dedicado); o JBR do Android Studio (`C:\Program Files\Android\Android Studio\jbr\bin`) foi adicionado
ao `PATH` só desta sessão de shell para rodar o Firestore/Storage Emulator — nenhuma configuração
permanente do sistema foi alterada.

## Decisões técnicas

- **`roleHasCapability` duplicado uma terceira vez** (Dart → `firestore.rules` → `storage.rules`),
  em vez de tentar gerar as rules a partir de uma fonte única: Storage Rules, assim como Firestore
  Rules, não executam Dart nem importam arquivos externos — a duplicação manual é a única forma
  disponível hoje. Documentado extensivamente no comentário no topo de `storage.rules`.
- **Cross-Service Security Rules (`firestore.get`/`firestore.exists`) em vez de duplicar o Membership
  como metadado do próprio arquivo de Storage.** Manter uma única fonte de verdade (o Membership no
  Firestore, já mantido por TASK-026/028) evita o risco de um metadado de Storage desatualizado
  autorizar algo que o Membership real já revogou (ex.: usuário desativado que ainda teria metadado
  "ativo" em um arquivo antigo). O custo é uma leitura de rede extra por avaliação de regra, aceitável
  para os volumes de escrita/leitura de mídia do app.
- **`catalog.manage` (não uma nova capability `product.manage`) para fotos de produto.** A task não
  exigia criar uma capability nova, e não existe ainda nenhum use case Dart que grave produto — a
  capability mais próxima e já existente na matriz (TASK-029) para "gerenciar o catálogo" é
  `catalog.manage`, hoje restrita a OWNER/ADMIN. Escolhida deliberadamente por ser administrativa (o
  próprio critério de aceite cita "excluir imagem de produto de outro usuário" como exemplo de ação
  administrativa) — se no futuro um perfil de "gestor de catálogo" mais amplo for modelado, revisar
  esta escolha junto da matriz Dart e do espelho em `firestore.rules`.
- **`order.create` (não uma capability nova de "gerenciar anexos") para anexos de pedido.** Anexar
  documentos é parte natural de criar/montar um pedido — reaproveitar `order.create` (já concedida a
  OWNER/ADMIN/SALES_MANAGER/SALES_REP) evita introduzir uma capability sem nenhum caso de uso Dart
  ainda modelado. Delete usa a mesma capability, já que não há hoje noção de "dono do anexo" que
  justificasse uma regra "só quem enviou pode excluir" nas Rules (não há metadado de autor persistido
  nem exigido pela task).
- **Avatar sem capability de RBAC, só verificação de identidade (`userId == request.auth.uid`).** Um
  avatar é sempre uma ação sobre o próprio perfil — nenhum papel do RBAC deveria poder gerenciar o
  avatar de outra pessoa (diferente de foto de produto/anexo de pedido, que são recursos
  organizacionais compartilhados). Leitura, porém, é aberta a qualquer membro ativo da organização,
  simetricamente ao que já é verdade para `companies`/`branches`/`roles`/`teams`/`members` em
  `firestore.rules` (nenhuma capability de leitura foi modelada em TASK-029).
- **Limites de tamanho (10 MB produto / 20 MB anexo / 5 MB avatar) e tipos de conteúdo permitidos são
  uma decisão desta task**, já que `tasks.md`/TASK-014/TASK-031 não fixam um número exato. Escolhidos
  para acomodar fotos de produto sem compressão prévia (a compressão client-side de
  `ImageUploadCompressor`, TASK-014, é best-effort, não garantida — a regra do servidor não pode
  assumir que toda imagem chegou já comprimida) e documentos comerciais comuns (PDF, Office) para
  anexos de pedido. Revisável sem quebrar isolamento/RBAC caso o produto decida limites diferentes.
- **Projeto de teste (`projectId`) de `storage-tests` precisou ser exatamente `vestipro`** (o mesmo
  de `.firebaserc`), não um id sintético como em `firestore-tests` (`vestipro-rules-test`): com
  `"singleProjectMode": true` (`firebase.json`), as chamadas Cross-Service de `storage.rules` para o
  Firestore resolvem sempre contra o projeto único configurado do emulador, não contra o `projectId`
  passado a `initializeTestEnvironment` — descoberto na primeira execução dos testes (todas as
  asserções positivas falhavam com "document not found" no log do Firestore Emulator, indicando que
  os dados semeados em `vestipro-storage-rules-test` nunca eram vistos pela leitura cross-service
  contra `vestipro`). Documentado com comentário extenso no próprio arquivo de teste para não se
  repetir por engano em uma suíte futura.

## Riscos conhecidos

- **Tripla duplicação da matriz RBAC** (`RolePermissionMatrix` Dart → `firestore.rules` →
  `storage.rules`): qualquer mudança futura em uma precisa ser replicada manualmente nas outras duas.
  Mesmo risco já registrado na TASK-030, agora com um lugar adicional para divergir. Não há teste de
  paridade automatizado entre as três hoje.
- **`catalog.manage`/`order.create` ainda não são exercidos por nenhum use case Dart real** (não
  existe feature de produto/pedido implementada ainda — chegam em EPICs futuros). As regras já
  suportam o caso futuro, mas só serão validadas de ponta a ponta (incluindo o client real) quando
  essas features existirem.
- **Sem metadado de "dono do arquivo"**: como Storage não persiste quem originalmente enviou um
  anexo de pedido/foto de produto (não há campo de autor nos metadados), a regra de exclusão não
  distingue "excluir o que eu mesmo enviei" de "excluir o que outra pessoa enviou" — ambas exigem a
  mesma capability administrativa. Se o produto precisar de uma regra mais granular (ex.: SALES_REP
  pode excluir seus próprios anexos, mas não os de outro rep), será necessário adicionar metadado
  customizado no upload (`customMetadata`) e uma nova condição na regra.
- **Ambiente sem JDK dedicado**: mesma limitação já registrada na TASK-030 — depende do JBR do
  Android Studio estar instalado nesta máquina para rodar o Firestore/Storage Emulator localmente.

## Pendências

- Nenhuma pendência bloqueando a conclusão desta task: `storage.rules` cobre os 3 tipos de mídia já
  modelados, com deny-by-default, validação de tipo/tamanho no próprio upload, e todos os testes
  (positivos, negativos, cross-tenant, tipo/tamanho inválidos e Membership inativo) passam no
  emulador real.
- TASK-032 (Firebase App Check) continua pendente, como já esperado pela ordem do backlog.
- Quando features reais de produto/pedido/perfil (EPIC-08 e além) começarem a usar
  `StorageDataSource` de fato, revisitar se os limites de tamanho/tipo escolhidos aqui continuam
  adequados, e se a ausência de metadado de "dono do arquivo" precisa ser resolvida para uma regra de
  exclusão mais granular (ver "Riscos conhecidos").

## Evidências

- `storage.rules` (raiz do repositório).
- `storage-tests/storage.rules.test.js` e saída do comando `firebase emulators:exec --only
  "firestore,storage" "npm --prefix storage-tests test"` (28/28 testes passando, reproduzida na
  seção "Resultado dos testes" acima).
- Regressão de `firestore-tests` (32/32, TASK-030) confirmando que nada em `firestore.rules` foi
  afetado por esta task.
- `flutter analyze` → `No issues found!`; `flutter test` → `All tests passed!` (632 testes).

## Commit

Realizado.

## Push

Não autorizado nesta execução — apenas commit local, conforme instrução explícita desta rodada.

## Hash do commit

`Ver resposta final da task (preenchido após o git commit real).`

## Branch

`main`
