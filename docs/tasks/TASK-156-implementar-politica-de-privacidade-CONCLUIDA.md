# TASK-156 — Implementar política de privacidade e termos (CONCLUÍDA)

**Epic:** EPIC-20 — LGPD e Privacidade
**Depende de:** TASK-020 (foundations do Design System)

## Resumo da solução

Foi criada a feature `privacy`, em Clean Architecture, com `PolicyDocument` versionado por tipo
(`privacy_policy` e `terms_of_use`) e `UserPolicyAcceptance` individual por usuário. As versões
vigentes são obtidas de `policyDocuments`; na ausência de conteúdo remoto, o aplicativo usa as duas
versões legais embarcadas de 05/09/2026. Uma publicação remota mais recente passa a ser a vigente
sem apagar qualquer documento anterior.

O `CurrentPolicyAcceptanceGuard`, conectado ao redirecionamento global do `AppRouter`, compara os
IDs `tipo_versão` vigentes com a subcollection
`users/{userId}/policyAcceptances/{tipo_versão}`. Primeiro acesso e versão nova levam à rota
`/policy-acceptance`, que não oferece acesso ao restante do app até o checkbox explícito e o botão
“Aceitar e continuar”. Depois do batch de aceite, o usuário volta à rota originalmente solicitada,
sem logout.

A mesma tela serve à leitura pública em `/terms-of-service` (inclusive antes do cadastro) e à rota
autenticada `/org/:orgId/settings/privacy`. O menu “Sobre o app” ganhou uma ação “Privacidade e
termos”, garantindo releitura permanente sem solicitar novo aceite.

## Persistência e segurança

- Cada aceite registra `userId`, `type`, `version`, `acceptedAt` (timestamp autoritativo do servidor)
  e `device` quando disponível.
- IDs distintos por tipo/versão impedem que um aceite antigo valide uma nova publicação.
- As Firestore Rules permitem leitura pública somente de documentos com `published == true`.
- O cliente não publica, atualiza ou exclui documentos legais.
- Aceites só podem ser criados pelo próprio usuário, com ID coerente e timestamp do servidor;
  atualização e exclusão são sempre negadas.
- O histórico é global por usuário, não por organização, evitando que o aceite de uma conta seja
  compartilhado com outra.

## Arquivos principais

- `lib/features/privacy/` — entidades, contrato, casos de uso, repository Firestore, guard, Cubit e
  tela responsiva/acessível de texto longo.
- `lib/core/navigation/` — rotas tipadas e extensão do guard global.
- `lib/app/bootstrap.dart` — composição da feature com autenticação e Firestore reais.
- `lib/features/settings/presentation/pages/about_app_page.dart` — acesso permanente pelo menu.
- `firestore.rules` e `firestore-tests/firestore.rules.test.js` — proteção e testes positivos/
  negativos da trilha de conformidade.
- `test/features/privacy/` — testes dos casos de uso e da interação explícita na tela.

## Validações executadas

- `flutter test test/features/privacy test/core/navigation/app_router_test.dart test/features/settings/presentation/pages/about_app_page_test.dart` — 33 testes passando.
- `flutter analyze` — sem erros; apenas infos pré-existentes fora da feature.
- `dart format` — aplicado nos arquivos Dart alterados.
- `firebase emulators:exec --only firestore "npm --prefix firestore-tests test"` — não executado até
  os testes porque o ambiente não possui Java no `PATH` (`spawn java ENOENT`). As regras e casos de
  teste foram adicionados, mas essa validação permanece pendente em ambiente com Java.

## Testes obrigatórios cobertos

- Primeiro acesso sem aceite retorna as duas versões como pendentes.
- Guard global bloqueia uma rota funcional e preserva seu `returnTo` para continuar após o aceite.
- Nova versão invalida o aceite da versão anterior.
- Registro inclui usuário, tipo, versão, data e dispositivo.
- Tela fora do bloqueio exibe ambos os documentos e não mostra controle de aceite.
- Checkbox explícito habilita o botão somente após a ação do usuário.
- Repositório consulta os aceites por `userId`; teste prova isolamento entre dois usuários.

## Decisões e riscos conhecidos

- A publicação de documentos legais é deliberadamente server-side/Admin SDK; não há UI cliente de
  publicação nesta task.
- Falha ao consultar a versão vigente fecha o acesso e mantém o usuário na tela legal com opção de
  tentar novamente. Isso evita liberar funcionalidades sem conseguir comprovar o aceite.
- Os textos embarcados são uma base operacional versionada. Revisão jurídica e publicação de uma
  nova versão podem ocorrer sem alteração do fluxo, criando um novo documento imutável no Firestore.
