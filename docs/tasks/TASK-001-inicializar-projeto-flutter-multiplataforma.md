# TASK-001 — Inicializar projeto Flutter multiplataforma

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** Nenhuma — primeira task do projeto

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar o projeto Flutter que servirá de base para todo o VestiPro, com suporte confirmado a iOS, Android e Web desde o primeiro commit. Esta task existe para eliminar retrabalho estrutural: qualquer decisão de plataforma, versionamento de SDK ou organização inicial de pastas tomada aqui condiciona as 205 tasks seguintes do backlog.

## Escopo técnico

- Criar o projeto com `flutter create` usando `org` reverso adequado (ex.: `br.com.malwee.vestipro` ou equivalente definido com o usuário) e `--platforms=android,ios,web`.
- Fixar a versão do Flutter/Dart SDK no `pubspec.yaml` (`environment: sdk`) e documentar a versão exata do Flutter usada (ex.: via `.fvmrc`/`fvm` ou comentário no README) para reprodutibilidade entre máquinas e CI.
- Criar as pastas vazias `lib/app/`, `lib/core/` e `lib/features/` (com `.gitkeep` se necessário) refletindo a estrutura definida na seção 4.1 de `tasks.md`, sem ainda popular subpastas de `core/` (isso é das tasks seguintes).
- Criar `README.md` inicial descrevendo o projeto (Força de Vendas B2B para moda, Flutter + Firebase, multi-tenant, offline-first), como rodar (`flutter pub get`, `flutter run`), e link para `tasks.md` e `docs/tasks/TASKS.md`.
- Criar/ajustar `.gitignore` cobrindo artefatos de build (`build/`, `.dart_tool/`, `ios/Pods/`, `android/.gradle`), arquivos de ambiente sensíveis (`*.env`, `google-services.json` de dev local se aplicável — decisão fina fica para TASK-010) e arquivos de IDE.
- Validar builds mínimos: `flutter build apk --debug` (Android), `flutter build ios --no-codesign --simulator` ou `flutter build ios --debug` (iOS, se ambiente macOS disponível — caso não esteja disponível no ambiente de execução, documentar como pendência explícita, nunca simular sucesso), `flutter build web` (Web).
- Se não houver repositório Git inicializado (`git status` falha com "not a git repository"), perguntar ao usuário nesta conversa antes de rodar `git init` e antes de criar o primeiro commit, conforme `AGENTS.md`.

## Regras de negócio e restrições

- Não incluir nenhuma lógica de negócio, autenticação ou Firebase nesta task — é puramente estrutural (Firebase entra a partir de EPIC-01).
- Não introduzir dependências fora do essencial do `flutter create`; dependências do projeto são escopo da TASK-003.
- Não commitar arquivos gerados de build, chaves de assinatura ou artefatos de plataforma específicos de uma máquina local.

## Testes obrigatórios

- Executar `flutter test` sobre o teste de smoke padrão gerado pelo `flutter create` (ou substituí-lo por um teste mínimo que valide que o `MaterialApp`/`WidgetsApp` inicial constrói sem erros).
- Validar `flutter analyze` sem erros/warnings na estrutura recém-criada.
- Confirmar que os três builds (Android, iOS quando possível, Web) completam sem erro de configuração de plataforma.

## Critérios de aceite

- Projeto Flutter criado na raiz do repositório com suporte declarado a Android, iOS e Web em `pubspec.yaml`/pastas de plataforma.
- Estrutura `lib/app/`, `lib/core/`, `lib/features/` presente e vazia (sem código de feature ainda).
- `README.md` e `.gitignore` criados e coerentes com o restante do backlog.
- `flutter analyze` e `flutter test` executam sem falhas.
- Pelo menos um build por plataforma foi tentado e o resultado (sucesso ou impedimento de ambiente) está documentado na evidência de conclusão da task.
- Repositório Git inicializado apenas mediante confirmação explícita do usuário nesta conversa, e primeiro commit criado somente após essa confirmação.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
