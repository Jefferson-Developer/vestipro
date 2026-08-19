# TASK-005 — Configurar gerenciamento de estado (BLoC/Cubit)

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-004 (arquitetura feature-first definida, módulo de exemplo com camada `presentation/` já existente para receber o BLoC de referência)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Fixar as convenções de uso de `flutter_bloc`/`bloc` que todas as features do VestiPro seguirão — nomenclatura de eventos/estados, tratamento de estados imutáveis, transformers para eventos concorrentes — e comprová-las com um BLoC funcional e testado, evitando que cada feature reinvente o padrão de estado.

## Escopo técnico

- Documentar em `docs/architecture/` (ou complementar o documento da TASK-004) a convenção de nomenclatura: um BLoC por fluxo funcional (nunca um único BLoC gigante por feature inteira), eventos nomeados como intenção (`OrderDraftItemAdded`, `OrderGridQuantityChanged`), estados nomeados como situação completa (`OrderDraftInitial`, `OrderDraftLoading`, `OrderDraftReady`, `OrderSubmitting`, `OrderSubmitFailure`).
- Implementar um BLoC (ou Cubit, quando o fluxo for simples o suficiente) real para o módulo de exemplo criado na TASK-004, usando `freezed` para estados imutáveis com igualdade por valor.
- Configurar transformers de evento adequados via pacote `bloc_concurrency` (ou implementação equivalente) demonstrando `sequential` para operações que devem ser ordenadas (ex.: submissão) e `restartable`/`droppable` para buscas/filtros que podem ser substituídos por uma nova intenção do usuário.
- Demonstrar no BLoC de exemplo o padrão de paginação que preserva itens já carregados (ainda que o BLoC de exemplo pagine uma lista mockada em memória, sem Firestore).
- Configurar `BlocObserver` central em `lib/app/` para logging estruturado de transições de estado em modo debug (nunca usando `print` — usar o `AppLogger` quando disponível, ou um placeholder documentado até a TASK-016).
- Configurar `bloc_test` no projeto com um exemplo de teste cobrindo a sequência completa de estados emitidos pelo BLoC de exemplo diante de um evento.

## Regras de negócio e restrições

- BLoC nunca deve depender de `BuildContext`, disparar navegação ou abrir diálogos diretamente — essas responsabilidades ficam na camada de apresentação (páginas/widgets) reagindo ao estado emitido.
- Estados parcialmente inválidos nunca devem ser emitidos; cada estado representa uma situação completa e consistente.
- Estados devem ser capazes de refletir a origem do dado (local/cache vs. remoto sincronizado) sempre que isso impactar a UI — mesmo no exemplo, incluir um campo/flag ilustrativo para fixar esse padrão desde já.
- BLoCs não instanciam repositórios diretamente; recebem dependências via injeção de dependência (mesmo que a DI completa só seja configurada na TASK-006, o BLoC de exemplo já deve receber o caso de uso via construtor).

## Testes obrigatórios

- Teste com `bloc_test` cobrindo o caminho feliz do BLoC de exemplo (sequência esperada de estados).
- Teste com `bloc_test` cobrindo um caminho de falha (ex.: caso de uso retorna `Failure`, BLoC emite estado de erro sem perder dados já carregados).
- Teste validando que eventos concorrentes (ex.: duas buscas disparadas em sequência rápida) resultam no comportamento esperado do transformer escolhido (a mais recente vence, ou execução sequencial, conforme o caso).
- Teste de regressão garantindo que o `BlocObserver` não lança exceção em nenhuma transição.

## Critérios de aceite

- Convenções de BLoC documentadas em `docs/architecture/`.
- BLoC/Cubit de exemplo implementado, com eventos/estados imutáveis via `freezed`.
- `BlocObserver` central configurado e registrado no bootstrap do app.
- `bloc_test` configurado e com pelo menos dois testes (sucesso e falha) passando.
- `flutter analyze` e `flutter test` passam sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
