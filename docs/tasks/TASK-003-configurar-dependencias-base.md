# TASK-003 — Configurar dependências base do pubspec

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-001 (inicializar projeto Flutter multiplataforma) — precisa do `pubspec.yaml` inicial gerado para adicionar e resolver as dependências sobre ele

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Estabelecer no `pubspec.yaml` o conjunto completo de dependências recomendadas pelo agente Flutter Senior para o VestiPro, cobrindo estado, navegação, modelos, injeção de dependência, banco local, Firebase, mídia e testes. Fazer isso de uma vez, de forma documentada, evita que cada task futura precise negociar critérios de escolha de pacote do zero.

## Escopo técnico

- Adicionar ao `pubspec.yaml` as dependências de produção: `flutter_bloc`, `bloc`, `get_it`, `injectable`, `go_router`, `freezed_annotation`, `json_annotation`, `collection`, `drift`, `drift_flutter`, `shared_preferences`, `flutter_secure_storage`, `connectivity_plus`, `cached_network_image`, `flutter_svg`, `intl`, `image_picker`, `file_picker`, `flutter_image_compress`, `photo_view`, `package_info_plus`, `device_info_plus`, `uuid`.
- Adicionar os pacotes Firebase que serão consumidos a partir do EPIC-01: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `cloud_functions`, `firebase_analytics`, `firebase_crashlytics`, `firebase_performance`, `firebase_messaging`, `firebase_remote_config`, `firebase_app_check` — mesmo que ainda não sejam inicializados nesta task (isso é da TASK-011 em diante), fixar as versões aqui evita conflitos de resolução mais tarde.
- Adicionar em `dev_dependencies`: `build_runner`, `freezed`, `json_serializable`, `drift_dev`, `injectable_generator`, `flutter_lints`, `bloc_test`, `mocktail`, `network_image_mock`.
- Adicionar `dio` apenas como dependência condicional/documentada (comentário no pubspec ou ADR) para uso futuro em integrações REST externas (ERP, API pública) — não usar para comunicação com Firebase, que utiliza SDKs próprios.
- Rodar `flutter pub get` e resolver quaisquer conflitos de versão entre pacotes (especialmente entre pacotes Firebase e `firebase_core`, e entre `drift`/`drift_dev`).
- Documentar em um arquivo de decisão (ex.: `docs/adr/0001-dependencias-base.md` ou seção no README) os critérios de escolha aplicados a cada pacote: versão estável (não `dev`/`beta` salvo justificativa), manutenção recente, compatibilidade declarada com Android/iOS/Web, ausência de sobreposição com outro pacote já escolhido.
- Explicitamente não adicionar pacotes da lista de "não devem ser adicionados automaticamente" do agente Flutter Senior (frameworks de arquitetura completos, outro gerenciador de estado, outro sistema de navegação, pacotes sem suporte às 3 plataformas).

## Regras de negócio e restrições

- Nenhum pacote deve ser adicionado "porque pode ser útil depois" sem necessidade real identificada nesta ou em tasks já mapeadas do backlog.
- Toda dependência deve declarar suporte a Android, iOS e Web (verificar página do pacote no pub.dev); pacotes apenas mobile ficam de fora ou são isolados atrás de uma abstração até que exista alternativa Web.
- Tokens, segredos e dados sensíveis nunca devem ser armazenados via `shared_preferences` — reservar isso para `flutter_secure_storage`, conforme já antecipado aqui mesmo sem uso ainda.

## Testes obrigatórios

- `flutter pub get` conclui sem erro de resolução de versões.
- `flutter analyze` não aponta erro após a adição das dependências (mesmo sem uso ainda de cada uma).
- `flutter test` do smoke test existente continua passando.
- Build de smoke (`flutter build web` ou `flutter build apk --debug`) confirma que a árvore de dependências resolvida não quebra o build.

## Critérios de aceite

- `pubspec.yaml` e `pubspec.lock` atualizados com todas as dependências listadas acima, em versões estáveis compatíveis entre si.
- Documento de decisão de dependências criado e referenciando os critérios usados.
- Nenhum pacote da lista de exclusão do agente Flutter Senior presente no projeto.
- `flutter pub get`, `flutter analyze` e `flutter test` executam sem erro.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
