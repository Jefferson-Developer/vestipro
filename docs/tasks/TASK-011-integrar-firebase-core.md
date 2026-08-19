# TASK-011 — Integrar Firebase Core

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-010 (projetos/apps Firebase e `firebase_options` por ambiente já criados — sem isso não há o que inicializar)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Inicializar o SDK `firebase_core` de forma correta e reprodutível em todos os entrypoints e nas três plataformas, garantindo que o restante do EPIC-01 (Auth, Firestore, Storage, Functions, Analytics, Crashlytics, Remote Config, Performance) tenha uma base de inicialização única e confiável para se apoiar.

## Escopo técnico

- Implementar `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` (ou variante equivalente por ambiente) dentro da função de bootstrap central em `lib/app/bootstrap.dart`, chamada a partir de `main_dev.dart`, `main_staging.dart` e `main_prod.dart` — nunca duplicando a chamada de inicialização em múltiplos pontos do app.
- Garantir `WidgetsFlutterBinding.ensureInitialized()` antes da inicialização do Firebase em todos os entrypoints.
- Tratar falha de inicialização do Firebase de forma explícita (capturar exceção, registrar via mecanismo de erro definido em `lib/core/errors/`, e exibir uma tela de erro amigável em vez de crash silencioso ou tela branca).
- Validar a inicialização nas três plataformas (Android, iOS quando disponível, Web) e nos três ambientes (dev, staging, prod) — para Web, confirmar que a configuração via `index.html`/`firebase_options` Web funciona corretamente (Web usa configuração JS/JSON distinta de Android/iOS).
- Documentar no README o que fazer caso a inicialização falhe (ex.: arquivo de configuração ausente, projeto Firebase incorreto para o ambiente).

## Regras de negócio e restrições

- A inicialização do Firebase deve ocorrer antes de qualquer chamada a serviços Firebase (Auth, Firestore etc.) em qualquer ponto do app — nenhuma feature deve assumir que pode inicializar o Firebase por conta própria.
- Erros de inicialização nunca devem ser engolidos silenciosamente; devem ser reportados (mesmo que, nesta task, apenas via log estruturado, já que Crashlytics só é configurado na TASK-016).
- Nenhum dado de produção deve ser acessado a partir de um build `dev`/`staging` por erro de seleção de `firebase_options`.

## Testes obrigatórios

- Teste (ou verificação documentada, já que `Firebase.initializeApp` depende de binding de plataforma) confirmando que o bootstrap chama a inicialização exatamente uma vez por execução do app.
- Validação manual/documentada da inicialização bem-sucedida em Android, Web e, quando disponível, iOS, para os três ambientes.
- Teste simulando falha de inicialização (ex.: opções inválidas) e confirmando que o app exibe a tela de erro amigável em vez de travar sem feedback.

## Critérios de aceite

- `Firebase.initializeApp` chamado corretamente no bootstrap central, usado por todos os entrypoints.
- Inicialização validada nas três plataformas e nos três ambientes, com evidência documentada na conclusão da task.
- Tratamento de erro de inicialização implementado e testado.
- `flutter analyze` e `flutter test` passam sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
