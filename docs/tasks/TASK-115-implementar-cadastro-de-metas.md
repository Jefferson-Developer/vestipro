# TASK-115 — Implementar cadastro de metas

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ⬜ Pendente
**Depende de:** TASK-114 (entidade Target e repositório definidos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o formulário de criação/edição de metas por período e dimensão (vendedor, equipe, empresa, coleção, categoria), respeitando RBAC — apenas gestor/admin pode criar metas para outros usuários; um `SALES_REP` só visualiza/edita a própria meta quando permitido.

## Escopo técnico

- Criar `CreateTargetUseCase`/`UpdateTargetUseCase` (domain) aplicando as validações da TASK-114 (período, valor, sobreposição) e a checagem de RBAC antes de persistir.
- Criar o formulário de meta com campos: dimensão (seletor de tipo + seletor do vendedor/equipe/empresa/coleção/categoria correspondente), período (datas ou seletor de mês/trimestre/ano), tipo de métrica, valor da meta e moeda.
- Implementar a regra de RBAC na camada de aplicação: `SALES_MANAGER`/`ADMIN` podem criar meta para qualquer vendedor/equipe da organização/empresa sob sua gestão; `SALES_REP` não pode criar meta para outro usuário (a UI oculta a opção, mas a validação real ocorre no caso de uso, nunca só na UI).
- Implementar Cubit (`TargetFormCubit`) com estados de loading, validação em tempo real (ex.: alerta de sobreposição de período antes de salvar), salvando e sucesso/erro.
- Tratar edição de meta já ativa: se houver progresso/realizado associado (dependência futura com a TASK-116), alertar antes de reduzir o valor da meta abaixo do já realizado.
- Adicionar eventos de Analytics (`target_created`, `target_updated`).

## Regras de negócio e restrições

- Apenas `OWNER`/`ADMIN`/`SALES_MANAGER` criam metas para terceiros; `SALES_REP` só pode ver a própria meta (edição, quando permitida por configuração da organização, restrita a campos não financeiros).
- Toda validação de RBAC e de regra de negócio (sobreposição, valores) ocorre na camada de aplicação/casos de uso, nunca só na UI.
- O formulário nunca permite salvar meta com período inválido ou sobreposto sem aviso explícito.
- Alterações em metas ativas geram registro de auditoria (quem alterou, valor anterior, valor novo).

## Testes obrigatórios

- Teste do caso de uso negando criação de meta para terceiro quando o usuário é `SALES_REP` (RBAC).
- Teste do caso de uso validando sobreposição de período e rejeitando quando aplicável.
- Teste de widget do formulário cobrindo: seleção de dimensão, validação de período, envio com sucesso, erro de validação, erro de permissão.
- Teste garantindo que a auditoria é registrada ao editar uma meta ativa.

## Critérios de aceite

- Gestor/admin conseguem criar metas por vendedor, equipe, empresa, coleção e categoria.
- `SALES_REP` não consegue criar/editar meta de terceiros (RBAC validado na aplicação, não só ocultado na UI).
- Sobreposição de período e valores inválidos são bloqueados com mensagem clara.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
