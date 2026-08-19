# TASK-009 — Configurar estrutura inicial de testes

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-004 (estrutura `lib/` feature-first definida, para espelhar em `test/`), TASK-005 (BLoC de exemplo existente, alvo do primeiro teste com `bloc_test`)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Estabelecer a estrutura de pastas e as convenções de teste (`test/` espelhando `lib/`) e configurar os pacotes de teste do VestiPro (`flutter_test`, `bloc_test`, `mocktail`, `golden_toolkit` quando aplicável), com exemplos funcionais de teste unitário e de widget, para que toda feature futura tenha um padrão claro a seguir e a cobertura recomendada (domínio 90%, casos de uso 90%, BLoCs 85%, repositórios 80%, mappers 100%) seja alcançável desde o início.

## Escopo técnico

- Criar a estrutura `test/` espelhando `lib/` (ex.: `test/features/<feature_exemplo>/domain/usecases/...`, `test/features/<feature_exemplo>/presentation/bloc/...`), aplicada inicialmente ao módulo de exemplo da TASK-004.
- Configurar `mocktail` para mockar contratos de repositório na camada de domínio, evitando dependência de mocks gerados por código (`mockito` com build_runner) para reduzir acoplamento a geração de código nos testes.
- Adicionar `golden_toolkit` ao pubspec (dev dependency) apenas se o time confirmar que fará golden tests de componentes visuais do Design System (EPIC-02); documentar a decisão e, caso adotado, configurar `loadAppFonts()`/`testGoldens` de exemplo com um widget simples.
- Escrever um teste unitário de exemplo cobrindo um caso de uso do módulo de exemplo (sucesso e falha), um teste de repositório mockando o datasource, e um teste de mapper DTO → Entidade.
- Escrever um teste de widget de exemplo para a página do módulo de exemplo, cobrindo os estados de loading, sucesso e erro renderizados a partir do BLoC (usando `BlocProvider`/`MockBloc` ou similar via `mocktail`).
- Documentar em `docs/architecture/` (ou `docs/testing.md`) a convenção de nomenclatura de arquivos de teste (`*_test.dart`), a meta de cobertura por camada, e como rodar `flutter test --coverage` localmente.

## Regras de negócio e restrições

- Testes de domínio não devem importar Flutter/widgets; testes de presentation não devem acessar datasource real.
- Mocks devem representar contratos (`abstract class`) de repositório/datasource, nunca a implementação concreta.
- Testes devem cobrir cenários de sucesso, falha previsível, valores limite, campos nulos/listas vazias — mesmo no exemplo, demonstrar ao menos um caso de cada categoria para fixar o padrão.
- Nenhum teste deve depender de rede real, Firebase real ou estado global compartilhado entre testes (usar `setUp`/`tearDown` para isolar estado).

## Testes obrigatórios

- Teste unitário do caso de uso do módulo de exemplo: caminho de sucesso.
- Teste unitário do caso de uso do módulo de exemplo: caminho de falha (retorno de `Failure` específica).
- Teste de repositório do módulo de exemplo usando `mocktail` para simular o datasource.
- Teste de mapper DTO → Entidade do módulo de exemplo.
- Teste de widget da página do módulo de exemplo cobrindo estados de loading/sucesso/erro.

## Critérios de aceite

- Estrutura `test/` criada espelhando `lib/`, com os exemplos descritos implementados e passando.
- `mocktail` configurado e em uso nos testes de exemplo.
- Decisão sobre `golden_toolkit` documentada (adotado ou não, e por quê).
- Documento de convenções de teste criado em `docs/`.
- `flutter test` (e `flutter test --coverage`, se configurado) executa sem falhas.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
