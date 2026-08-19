# TASK-006 — Configurar injeção de dependência

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-004 (estrutura feature-first e módulo de exemplo existentes para servir de alvo do registro de dependências)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Configurar `get_it` + `injectable` como mecanismo único e central de injeção de dependência do VestiPro, para que repositórios, casos de uso e BLoCs sejam sempre resolvidos por construtor a partir de um bootstrap único, nunca instanciados manualmente ou acessados via `GetIt.instance` espalhado pelo código.

## Escopo técnico

- Adicionar `build_runner` + `injectable_generator` (já presentes no pubspec pela TASK-003) à configuração de geração de código do projeto, criando o arquivo `lib/app/injection.dart` (ou `lib/core/di/injection.dart`) com a configuração `@InjectableInit`.
- Anotar as classes do módulo de exemplo (datasource, repositório, caso de uso, BLoC) com `@injectable`/`@lazySingleton`/`@factory` conforme a convenção: datasources e repositórios como `@lazySingleton` (uma instância reaproveitada), casos de uso como `@injectable` (instância por resolução, stateless), BLoCs como `@injectable`/`@factory` (nova instância por tela/uso), documentando essa convenção em `docs/architecture/`.
- Chamar `configureDependencies()` (ou nome equivalente) uma única vez no bootstrap de `lib/app/`, antes do `runApp`, nos três entrypoints (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`).
- Garantir que nenhuma camada de domínio (`domain/`) referencie `GetIt` diretamente — apenas a camada de apresentação/bootstrap resolve dependências do container, e o faz preferencialmente via `BlocProvider`/injeção por construtor em vez de chamadas soltas a `getIt<T>()` no meio de widgets.
- Rodar `flutter pub run build_runner build --delete-conflicting-outputs` e versionar (ou não, conforme convenção do time) o resultado gerado (`injection.config.dart`), documentando a decisão.

## Regras de negócio e restrições

- Repositórios nunca dependem de BLoCs; BLoCs nunca criam repositórios manualmente com `new`/construtor direto fora do container.
- Não deve haver singletons manuais (variáveis globais mutáveis guardando instâncias) fora do container do `get_it`.
- Não criar ciclos de dependência entre módulos registrados.
- Ambientes distintos (dev/staging/prod) podem registrar implementações diferentes do mesmo contrato (ex.: um datasource fake em dev vs. real em prod) usando os `environment`/`@Environment` do `injectable` — preparar essa capacidade mesmo que ainda não haja uso real além do exemplo.

## Testes obrigatórios

- Teste validando que `configureDependencies()` executa sem lançar exceção e resolve corretamente as dependências do módulo de exemplo (`getIt<ExemploRepository>()` retorna uma instância válida).
- Teste garantindo que uma dependência registrada como `@lazySingleton` retorna a mesma instância em duas resoluções, e uma registrada como `@factory` retorna instâncias distintas.
- Teste de regressão simples confirmando que o BLoC de exemplo, quando resolvido via container, recebe o caso de uso correto (não um mock acidental).

## Critérios de aceite

- `get_it` + `injectable` configurados e funcionando para o módulo de exemplo.
- Convenção de lazy singleton/factory documentada em `docs/architecture/`.
- Bootstrap de DI chamado nos três entrypoints antes do `runApp`.
- Código gerado (`*.config.dart`) presente e atualizado, sem erros de geração.
- `flutter analyze` e `flutter test` passam sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
