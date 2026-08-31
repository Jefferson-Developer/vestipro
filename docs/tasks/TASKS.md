# Backlog Técnico — VestiPro (Força de Vendas Mobile para Moda B2B)

Este é o índice mestre do backlog. Ele reflete e expande a especificação completa em
[`tasks.md`](../../tasks.md) (raiz do projeto), quebrada em tasks individuais, no padrão descrito em
[`AGENTS.md`](../../AGENTS.md).

O backlog original (seção 18 de `tasks.md`) tinha 120 tasks amplas em 20 EPICs. Este índice expande
para **220 tasks em 33 EPICs**: cada task original foi quebrada em passos menores e mais executáveis,
foi adicionado um EPIC de Design System (que faltava, apesar de exigido na seção 6 da especificação),
e toda a lista de "evolução pós-MVP" (seção 19 de `tasks.md`) foi transformada em tasks reais e
sequenciáveis (EPICs 22–31). Depois de uma revisão final de lacunas para venda B2B de moda, também
foi adicionado o EPIC-32, cobrindo packs/sortimentos, pré-venda, crédito, cobrança, expedição,
sell-out e qualidade de dados, para que o VestiPro possa de fato se tornar o sistema de força de vendas
mobile mais completo do mercado de moda — não apenas no MVP, mas na visão completa de produto.

## Como retomar o trabalho

- **A task "atual" é sempre a primeira com checkbox `[ ]` não marcado nesta lista**, na ordem em que
  aparecem. A ordem reflete dependências reais entre módulos (ex.: RBAC antes de telas
  administrativas; modelo de produto antes de grade comercial; Outbox antes de pedido offline).
- Para rodar a próxima task pendente, diga (ou use o comando do Claude Code):

  ```
  /proxima-task
  ```

  ou, em qualquer ferramenta (Claude Code ou Codex CLI), a frase equivalente:

  ```
  Rode a próxima task pendente do backlog em docs/tasks/TASKS.md
  ```

  Ambas instruem o agente a: abrir este arquivo, achar o primeiro checkbox `[ ]`, abrir o arquivo
  `docs/tasks/TASK-XXX-*.md` correspondente e seguir o fluxo obrigatório descrito em `AGENTS.md`.
- Para rodar **várias** tasks pendentes em sequência, escolhendo a quantidade, use (no Claude Code):

  ```
  /proximas-tasks
  ```

  ou a frase equivalente em qualquer ferramenta (Claude Code ou Codex CLI):

  ```
  Roda as próximas 3 tasks pendentes do backlog em docs/tasks/TASKS.md
  ```

  Isso repete o fluxo de `/proxima-task` uma task por vez, documentando e commitando ao final de
  cada uma (nunca só ao final do lote), e — sempre que a ferramenta suportar subagentes — isola cada
  task em um subagente novo para manter o contexto principal limpo entre uma task e outra. Detalhe
  completo em `AGENTS.md`.
- Ao concluir uma task, o agente deve marcar o checkbox correspondente aqui **no mesmo commit** que
  documenta e finaliza a task (quando houver Git configurado). Nunca marque uma task como concluída
  sem a implementação e os testes correspondentes.

## Regras que nunca mudam (resumo — detalhe completo em `AGENTS.md`)

- Toda task usa obrigatoriamente os agentes técnicos indicados na coluna "Agentes"
  (`flutter-senior-architect` e/ou `flutter-ui-design-specialist`) e, quando o escopo for
  comercial/gerencial, também os agentes de negócio definidos em `AGENTS.md`
  (`vestipro-sales-representative-specialist` e/ou `vestipro-commercial-ops-strategist`).
- Toda task termina com `dart format`, `flutter analyze`, `flutter test` (e o que mais for aplicável).
- Toda task gera `docs/tasks/TASK-XXX-nome-da-task.md` (já existente) e, ao concluir,
  `docs/tasks/TASK-XXX-nome-da-task-CONCLUIDA.md` (evidência de conclusão).
- Toda task termina com commit (padrão `tipo(modulo): descrição`) quando houver repositório Git.
- Nenhuma regra crítica (autorização, preço, número de pedido, aprovações) pode depender só do
  cliente — sempre validada em Cloud Function / Security Rules.
- Nunca quebrar isolamento multi-tenant nem operação offline existente.
- Se o commit/push não puder ser feito, o agente deve dizer isso claramente — nunca inventar hash
  nem marcar a task como concluída.

## Fases sugeridas (visão macro)

```text
Fase 1 — Fundação      : EPIC-00 a EPIC-05 (arquitetura, Firebase, Design System, segurança, auth)
Fase 2 — Core Comercial: EPIC-06 a EPIC-13 (clientes, CRM, produtos, grades, catálogo, preço, estoque, pedidos)
Fase 3 — Offline & BI  : EPIC-14 a EPIC-18 (sincronização, metas, insights, dashboards, relatórios)
Fase 4 — Engajamento   : EPIC-19 a EPIC-21 (notificações, LGPD, qualidade/release) — fim do MVP
Fase 5 — Evolução      : EPIC-22 a EPIC-32 (integrações, IA, portal B2B, pós-venda, data platform, operações avançadas)
```

---

## Índice

### EPIC-00 — Fundação e Arquitetura
- [x] [TASK-001 — Inicializar projeto Flutter multiplataforma](TASK-001-inicializar-projeto-flutter-multiplataforma.md) — Flutter Senior
- [x] [TASK-002 — Configurar ambientes dev/staging/prod](TASK-002-configurar-ambientes-dev-staging-prod.md) — Flutter Senior
- [x] [TASK-003 — Configurar dependências base do pubspec](TASK-003-configurar-dependencias-base.md) — Flutter Senior
- [x] [TASK-004 — Definir arquitetura feature-first + Clean Architecture](TASK-004-definir-arquitetura-feature-first.md) — Flutter Senior
- [x] [TASK-005 — Configurar gerenciamento de estado (BLoC/Cubit)](TASK-005-configurar-gerenciamento-de-estado-bloc.md) — Flutter Senior
- [x] [TASK-006 — Configurar injeção de dependência](TASK-006-configurar-injecao-de-dependencia.md) — Flutter Senior
- [x] [TASK-007 — Configurar navegação principal](TASK-007-configurar-navegacao-principal.md) — Flutter Senior
- [x] [TASK-008 — Configurar qualidade estática](TASK-008-configurar-qualidade-estatica.md) — Flutter Senior
- [x] [TASK-009 — Configurar estrutura inicial de testes](TASK-009-configurar-estrutura-inicial-de-testes.md) — Flutter Senior

### EPIC-01 — Firebase e Observabilidade
- [x] [TASK-010 — Criar e configurar projetos Firebase](TASK-010-criar-projetos-firebase.md) — Flutter Senior
- [x] [TASK-011 — Integrar Firebase Core](TASK-011-integrar-firebase-core.md) — Flutter Senior
- [x] [TASK-012 — Configurar Firebase Authentication (base)](TASK-012-configurar-firebase-authentication-base.md) — Flutter Senior
- [x] [TASK-013 — Configurar Cloud Firestore](TASK-013-configurar-cloud-firestore.md) — Flutter Senior
- [x] [TASK-014 — Configurar Firebase Storage](TASK-014-configurar-firebase-storage.md) — Flutter Senior
- [x] [TASK-015 — Configurar Cloud Functions for Firebase](TASK-015-configurar-cloud-functions.md) — Flutter Senior
- [x] [TASK-016 — Configurar Firebase Crashlytics](TASK-016-configurar-firebase-crashlytics.md) — Flutter Senior
- [x] [TASK-017 — Configurar Firebase Analytics](TASK-017-configurar-firebase-analytics.md) — Flutter Senior
- [x] [TASK-018 — Configurar Firebase Remote Config](TASK-018-configurar-firebase-remote-config.md) — Flutter Senior
- [x] [TASK-019 — Configurar Firebase Performance Monitoring](TASK-019-configurar-firebase-performance-monitoring.md) — Flutter Senior

### EPIC-02 — Design System
- [x] [TASK-020 — Criar foundations do Design System](TASK-020-criar-design-system-foundations.md) — Front-end
- [x] [TASK-021 — Criar componentes base](TASK-021-criar-componentes-base.md) — Front-end
- [x] [TASK-022 — Criar componentes de formulário e feedback](TASK-022-criar-componentes-de-formulario-e-feedback.md) — Front-end
- [x] [TASK-023 — Criar componentes de dados (tabelas, listas, KPI, gráficos)](TASK-023-criar-componentes-de-dados.md) — Front-end
- [x] [TASK-024 — Criar componentes de catálogo (grid, grade, cor, stepper)](TASK-024-criar-componentes-de-catalogo.md) — Front-end
- [x] [TASK-025 — Criar layouts responsivos](TASK-025-criar-layouts-responsivos.md) — Front-end

### EPIC-03 — Segurança e Multi-Tenancy
- [x] [TASK-026 — Modelar Organization](TASK-026-modelar-organization.md) — Flutter Senior
- [x] [TASK-027 — Modelar Company e Branch](TASK-027-modelar-company-e-branch.md) — Flutter Senior
- [x] [TASK-028 — Modelar Team, Role e vínculos de usuário](TASK-028-modelar-team-role-e-vinculos.md) — Flutter Senior
- [x] [TASK-029 — Implementar RBAC](TASK-029-implementar-rbac.md) — Flutter Senior
- [x] [TASK-030 — Criar Firestore Security Rules](TASK-030-criar-firestore-security-rules.md) — Flutter Senior
- [x] [TASK-031 — Criar Storage Security Rules](TASK-031-criar-storage-security-rules.md) — Flutter Senior
- [x] [TASK-032 — Configurar Firebase App Check](TASK-032-configurar-firebase-app-check.md) — Flutter Senior
- [x] [TASK-033 — Implementar auditoria administrativa (audit log central)](TASK-033-implementar-auditoria-administrativa.md) — Flutter Senior

### EPIC-04 — Autenticação e Onboarding
- [x] [TASK-034 — Implementar tela de login](TASK-034-implementar-tela-de-login.md) — Flutter Senior + Front-end
- [x] [TASK-035 — Implementar cadastro inicial de usuário](TASK-035-implementar-cadastro-inicial-de-usuario.md) — Flutter Senior + Front-end
- [x] [TASK-036 — Implementar recuperação de senha](TASK-036-implementar-recuperacao-de-senha.md) — Flutter Senior + Front-end
- [x] [TASK-037 — Implementar criação da primeira Organization](TASK-037-implementar-criacao-da-primeira-organizacao.md) — Flutter Senior
- [x] [TASK-038 — Implementar wizard de configuração inicial](TASK-038-implementar-wizard-de-configuracao-inicial.md) — Flutter Senior + Front-end
- [x] [TASK-039 — Implementar convite de usuários](TASK-039-implementar-convite-de-usuarios.md) — Flutter Senior + Front-end
- [x] [TASK-040 — Implementar aceite de convite e vínculo de conta](TASK-040-implementar-aceite-de-convite.md) — Flutter Senior + Front-end
- [x] [TASK-041 — Implementar sessão persistente, logout e revogação](TASK-041-implementar-sessao-persistente-e-logout.md) — Flutter Senior

### EPIC-05 — Usuários e Equipes
- [x] [TASK-042 — Implementar lista de usuários da organização](TASK-042-implementar-lista-de-usuarios.md) — Flutter Senior + Front-end
- [x] [TASK-043 — Implementar gestão de perfis e permissões](TASK-043-implementar-gestao-de-perfis-e-permissoes.md) — Flutter Senior + Front-end
- [x] [TASK-044 — Implementar equipes comerciais](TASK-044-implementar-equipes-comerciais.md) — Flutter Senior + Front-end
- [x] [TASK-045 — Implementar vínculo de vendedores a carteiras](TASK-045-implementar-vinculo-de-carteiras.md) — Flutter Senior + Front-end
- [x] [TASK-046 — Implementar desativação de usuário](TASK-046-implementar-desativacao-de-usuario.md) — Flutter Senior + Front-end
- [x] [TASK-047 — Implementar tela de auditoria de acessos](TASK-047-implementar-tela-de-auditoria-de-acessos.md) — Flutter Senior + Front-end

### EPIC-06 — Clientes
- [x] [TASK-048 — Modelar Customer](TASK-048-modelar-customer.md) — Flutter Senior
- [x] [TASK-049 — Implementar cadastro de cliente](TASK-049-implementar-cadastro-de-cliente.md) — Flutter Senior + Front-end
- [x] [TASK-050 — Implementar endereços e contatos do cliente](TASK-050-implementar-enderecos-e-contatos.md) — Flutter Senior + Front-end
- [x] [TASK-051 — Implementar carteira de clientes](TASK-051-implementar-carteira-de-clientes.md) — Flutter Senior + Front-end
- [x] [TASK-052 — Implementar detalhe do cliente 360º](TASK-052-implementar-detalhe-do-cliente-360.md) — Flutter Senior + Front-end
- [x] [TASK-053 — Implementar segmentação dinâmica de clientes](TASK-053-implementar-segmentacao-de-clientes.md) — Flutter Senior + Front-end
- [x] [TASK-054 — Implementar carga offline inicial de clientes](TASK-054-implementar-carga-offline-de-clientes.md) — Flutter Senior

### EPIC-07 — CRM
- [x] [TASK-055 — Modelar Lead](TASK-055-modelar-lead.md) — Flutter Senior
- [x] [TASK-056 — Implementar cadastro e listagem de leads](TASK-056-implementar-cadastro-e-listagem-de-leads.md) — Flutter Senior + Front-end
- [x] [TASK-057 — Modelar Opportunity](TASK-057-modelar-opportunity.md) — Flutter Senior
- [x] [TASK-058 — Implementar funil de vendas configurável](TASK-058-implementar-funil-de-vendas.md) — Flutter Senior + Front-end
- [x] [TASK-059 — Implementar atividades CRM (timeline)](TASK-059-implementar-atividades-crm.md) — Flutter Senior + Front-end
- [x] [TASK-060 — Implementar tarefas e follow-ups](TASK-060-implementar-tarefas-e-follow-ups.md) — Flutter Senior + Front-end
- [x] [TASK-061 — Implementar motivos de perda e ganho](TASK-061-implementar-motivos-de-perda-e-ganho.md) — Flutter Senior + Front-end
- [x] [TASK-062 — Implementar score do cliente e health score](TASK-062-implementar-score-e-health-score.md) — Flutter Senior
- [x] [TASK-063 — Implementar próxima melhor ação](TASK-063-implementar-proxima-melhor-acao.md) — Flutter Senior + Front-end

### EPIC-08 — Produtos e Catálogo Base
- [x] [TASK-064 — Modelar Product](TASK-064-modelar-product.md) — Flutter Senior
- [x] [TASK-065 — Implementar cadastro/edição de produto](TASK-065-implementar-cadastro-de-produto.md) — Flutter Senior + Front-end
- [x] [TASK-066 — Implementar coleções e estações](TASK-066-implementar-colecoes-e-estacoes.md) — Flutter Senior + Front-end
- [x] [TASK-067 — Implementar categorias e subcategorias](TASK-067-implementar-categorias-e-subcategorias.md) — Flutter Senior + Front-end
- [x] [TASK-068 — Implementar fotos e vídeos de produto](TASK-068-implementar-fotos-e-videos-de-produto.md) — Flutter Senior + Front-end
- [x] [TASK-069 — Implementar busca global de produtos](TASK-069-implementar-busca-global-de-produtos.md) — Flutter Senior + Front-end

### EPIC-09 — Cores, Grades e Variantes
- [x] [TASK-070 — Implementar cadastro de cores](TASK-070-implementar-cadastro-de-cores.md) — Flutter Senior + Front-end
- [x] [TASK-071 — Implementar templates de grade de tamanho](TASK-071-implementar-templates-de-grade.md) — Flutter Senior + Front-end
- [x] [TASK-072 — Implementar geração de variantes produto-cor-tamanho](TASK-072-implementar-geracao-de-variantes.md) — Flutter Senior
- [x] [TASK-073 — Implementar UI de grade comercial](TASK-073-implementar-ui-de-grade-comercial.md) — Flutter Senior + Front-end
- [x] [TASK-074 — Implementar disponibilidade por variante](TASK-074-implementar-disponibilidade-por-variante.md) — Flutter Senior + Front-end
- [x] [TASK-075 — Implementar ordenação personalizada de tamanhos](TASK-075-implementar-ordenacao-de-tamanhos.md) — Flutter Senior + Front-end

### EPIC-10 — Catálogo Premium
- [x] [TASK-076 — Implementar home do catálogo](TASK-076-implementar-home-do-catalogo.md) — Flutter Senior + Front-end
- [x] [TASK-077 — Implementar grid visual de produtos](TASK-077-implementar-grid-visual-de-produtos.md) — Flutter Senior + Front-end
- [x] [TASK-078 — Implementar detalhe visual de produto](TASK-078-implementar-detalhe-visual-de-produto.md) — Flutter Senior + Front-end
- [x] [TASK-079 — Implementar favoritos](TASK-079-implementar-favoritos.md) — Flutter Senior + Front-end
- [x] [TASK-080 — Implementar lookbook e campanhas visuais](TASK-080-implementar-lookbook-e-campanhas.md) — Flutter Senior + Front-end
- [x] [TASK-081 — Implementar compartilhamento de catálogo](TASK-081-implementar-compartilhamento-de-catalogo.md) — Flutter Senior + Front-end
- [x] [TASK-082 — Implementar modos de visualização e filtros avançados](TASK-082-implementar-modos-de-visualizacao-e-filtros.md) — Flutter Senior + Front-end

### EPIC-11 — Tabelas de Preço e Condições Comerciais
- [x] [TASK-083 — Modelar Price List](TASK-083-modelar-price-list.md) — Flutter Senior
- [x] [TASK-084 — Implementar preço por produto/variante](TASK-084-implementar-preco-por-produto-variante.md) — Flutter Senior + Front-end
- [x] [TASK-085 — Implementar condições de pagamento](TASK-085-implementar-condicoes-de-pagamento.md) — Flutter Senior + Front-end
- [x] [TASK-086 — Implementar políticas de desconto por perfil](TASK-086-implementar-politicas-de-desconto.md) — Flutter Senior + Front-end
- [x] [TASK-087 — Implementar campanhas promocionais](TASK-087-implementar-campanhas-promocionais.md) — Flutter Senior + Front-end
- [x] [TASK-088 — Implementar motor de precificação server-side](TASK-088-implementar-motor-de-precificacao.md) — Flutter Senior

### EPIC-12 — Estoque e Disponibilidade
- [x] [TASK-089 — Modelar Warehouse](TASK-089-modelar-warehouse.md) — Flutter Senior
- [x] [TASK-090 — Implementar saldo por variante](TASK-090-implementar-saldo-por-variante.md) — Flutter Senior
- [x] [TASK-091 — Implementar estoque futuro](TASK-091-implementar-estoque-futuro.md) — Flutter Senior + Front-end
- [x] [TASK-092 — Implementar reserva comercial](TASK-092-implementar-reserva-comercial.md) — Flutter Senior
- [x] [TASK-093 — Implementar alertas de ruptura](TASK-093-implementar-alertas-de-ruptura.md) — Flutter Senior + Front-end
- [x] [TASK-094 — Implementar indicadores de giro de estoque](TASK-094-implementar-indicadores-de-giro-de-estoque.md) — Flutter Senior

### EPIC-13 — Pedidos
- [x] [TASK-095 — Modelar Order e OrderItem](TASK-095-modelar-order-e-order-item.md) — Flutter Senior
- [x] [TASK-096 — Implementar pedido em rascunho](TASK-096-implementar-pedido-em-rascunho.md) — Flutter Senior + Front-end
- [x] [TASK-097 — Implementar adição de produtos ao pedido via catálogo](TASK-097-implementar-adicao-de-produtos-ao-pedido.md) — Flutter Senior + Front-end
- [x] [TASK-098 — Implementar tela de grade no pedido](TASK-098-implementar-tela-de-grade-no-pedido.md) — Flutter Senior + Front-end
- [x] [TASK-099 — Implementar resumo comercial do pedido](TASK-099-implementar-resumo-comercial-do-pedido.md) — Flutter Senior + Front-end
- [x] [TASK-100 — Implementar validações antes do envio](TASK-100-implementar-validacoes-antes-do-envio.md) — Flutter Senior + Front-end
- [x] [TASK-101 — Implementar submissão do pedido](TASK-101-implementar-submissao-do-pedido.md) — Flutter Senior
- [x] [TASK-102 — Implementar listagem e acompanhamento de pedidos](TASK-102-implementar-listagem-de-pedidos.md) — Flutter Senior + Front-end
- [x] [TASK-103 — Implementar aprovação de pedidos](TASK-103-implementar-aprovacao-de-pedidos.md) — Flutter Senior + Front-end
- [x] [TASK-104 — Implementar histórico e duplicação de pedido](TASK-104-implementar-historico-e-duplicacao-de-pedido.md) — Flutter Senior + Front-end

### EPIC-14 — Offline e Sincronização
- [x] [TASK-105 — Criar ADR de banco local (Drift vs. Isar)](TASK-105-criar-adr-de-banco-local.md) — Flutter Senior
- [ ] [TASK-106 — Modelar schema local (Drift)](TASK-106-modelar-schema-local-drift.md) — Flutter Senior
- [ ] [TASK-107 — Criar pacote de carga offline](TASK-107-criar-pacote-de-carga-offline.md) — Flutter Senior
- [ ] [TASK-108 — Implementar Outbox](TASK-108-implementar-outbox.md) — Flutter Senior
- [ ] [TASK-109 — Implementar motor de sincronização incremental](TASK-109-implementar-motor-de-sincronizacao.md) — Flutter Senior
- [ ] [TASK-110 — Implementar resolução de conflitos](TASK-110-implementar-resolucao-de-conflitos.md) — Flutter Senior
- [ ] [TASK-111 — Implementar tela de conflito](TASK-111-implementar-tela-de-conflito.md) — Flutter Senior + Front-end
- [ ] [TASK-112 — Implementar central de sincronização](TASK-112-implementar-central-de-sincronizacao.md) — Flutter Senior + Front-end
- [ ] [TASK-113 — Implementar indicador de conectividade](TASK-113-implementar-indicador-de-conectividade.md) — Flutter Senior + Front-end

### EPIC-15 — Metas e Performance Comercial
- [ ] [TASK-114 — Modelar Target](TASK-114-modelar-target.md) — Flutter Senior
- [ ] [TASK-115 — Implementar cadastro de metas](TASK-115-implementar-cadastro-de-metas.md) — Flutter Senior + Front-end
- [ ] [TASK-116 — Implementar dashboard de atingimento](TASK-116-implementar-dashboard-de-atingimento.md) — Flutter Senior + Front-end
- [ ] [TASK-117 — Implementar positivação de carteira](TASK-117-implementar-positivacao-de-carteira.md) — Flutter Senior + Front-end
- [ ] [TASK-118 — Implementar ranking comercial](TASK-118-implementar-ranking-comercial.md) — Flutter Senior + Front-end
- [ ] [TASK-119 — Implementar projeção de fechamento](TASK-119-implementar-projecao-de-fechamento.md) — Flutter Senior + Front-end
- [ ] [TASK-120 — Implementar alertas de meta](TASK-120-implementar-alertas-de-meta.md) — Flutter Senior + Front-end

### EPIC-16 — Insights e Recomendação
- [ ] [TASK-121 — Criar engine base de insights](TASK-121-criar-engine-base-de-insights.md) — Flutter Senior
- [ ] [TASK-122 — Implementar insight de cliente inativo](TASK-122-implementar-insight-de-cliente-inativo.md) — Flutter Senior
- [ ] [TASK-123 — Implementar insight de queda de faturamento](TASK-123-implementar-insight-de-queda-de-faturamento.md) — Flutter Senior
- [ ] [TASK-124 — Implementar insight de cliente em crescimento](TASK-124-implementar-insight-de-cliente-em-crescimento.md) — Flutter Senior
- [ ] [TASK-125 — Implementar insight de cross-sell](TASK-125-implementar-insight-de-cross-sell.md) — Flutter Senior
- [ ] [TASK-126 — Implementar insight de up-sell](TASK-126-implementar-insight-de-up-sell.md) — Flutter Senior
- [ ] [TASK-127 — Implementar insight de mix insuficiente](TASK-127-implementar-insight-de-mix-insuficiente.md) — Flutter Senior
- [ ] [TASK-128 — Implementar insight de estoque alto/giro baixo e reposição](TASK-128-implementar-insight-de-estoque-e-reposicao.md) — Flutter Senior
- [ ] [TASK-129 — Implementar insight de risco de churn](TASK-129-implementar-insight-de-risco-de-churn.md) — Flutter Senior
- [ ] [TASK-130 — Implementar insight de pedido abandonado/carrinho salvo](TASK-130-implementar-insight-de-pedido-abandonado.md) — Flutter Senior
- [ ] [TASK-131 — Implementar insight de vendedor abaixo da meta](TASK-131-implementar-insight-de-vendedor-abaixo-da-meta.md) — Flutter Senior
- [ ] [TASK-132 — Implementar central de oportunidades](TASK-132-implementar-central-de-oportunidades.md) — Flutter Senior + Front-end

### EPIC-17 — Dashboards e BI
- [ ] [TASK-133 — Criar camada de agregação server-side](TASK-133-criar-camada-de-agregacao-server-side.md) — Flutter Senior
- [ ] [TASK-134 — Implementar dashboard executivo](TASK-134-implementar-dashboard-executivo.md) — Flutter Senior + Front-end
- [ ] [TASK-135 — Implementar dashboard de vendas](TASK-135-implementar-dashboard-de-vendas.md) — Flutter Senior + Front-end
- [ ] [TASK-136 — Implementar dashboard de clientes](TASK-136-implementar-dashboard-de-clientes.md) — Flutter Senior + Front-end
- [ ] [TASK-137 — Implementar dashboard de produtos](TASK-137-implementar-dashboard-de-produtos.md) — Flutter Senior + Front-end
- [ ] [TASK-138 — Implementar dashboard de coleção](TASK-138-implementar-dashboard-de-colecao.md) — Flutter Senior + Front-end
- [ ] [TASK-139 — Implementar dashboard de estoque](TASK-139-implementar-dashboard-de-estoque.md) — Flutter Senior + Front-end
- [ ] [TASK-140 — Implementar dashboard do representante](TASK-140-implementar-dashboard-do-representante.md) — Flutter Senior + Front-end
- [ ] [TASK-141 — Implementar dashboard de funil (CRM)](TASK-141-implementar-dashboard-de-funil.md) — Flutter Senior + Front-end
- [ ] [TASK-142 — Implementar dashboard de metas](TASK-142-implementar-dashboard-de-metas.md) — Flutter Senior + Front-end
- [ ] [TASK-143 — Implementar dashboard geográfico](TASK-143-implementar-dashboard-geografico.md) — Flutter Senior + Front-end

### EPIC-18 — Relatórios Customizados e Exportações
- [ ] [TASK-144 — Implementar construtor de relatórios](TASK-144-implementar-construtor-de-relatorios.md) — Flutter Senior + Front-end
- [ ] [TASK-145 — Implementar visualizações salvas e compartilhadas](TASK-145-implementar-visualizacoes-salvas.md) — Flutter Senior + Front-end
- [ ] [TASK-146 — Implementar exportação CSV](TASK-146-implementar-exportacao-csv.md) — Flutter Senior
- [ ] [TASK-147 — Implementar exportação XLSX](TASK-147-implementar-exportacao-xlsx.md) — Flutter Senior
- [ ] [TASK-148 — Implementar exportação PDF](TASK-148-implementar-exportacao-pdf.md) — Flutter Senior + Front-end
- [ ] [TASK-149 — Implementar agendamento de relatórios](TASK-149-implementar-agendamento-de-relatorios.md) — Flutter Senior

### EPIC-19 — Notificações e Engajamento
- [ ] [TASK-150 — Configurar Firebase Cloud Messaging](TASK-150-configurar-firebase-cloud-messaging.md) — Flutter Senior
- [ ] [TASK-151 — Implementar central de notificações internas](TASK-151-implementar-central-de-notificacoes.md) — Flutter Senior + Front-end
- [ ] [TASK-152 — Implementar notificações de CRM](TASK-152-implementar-notificacoes-de-crm.md) — Flutter Senior + Front-end
- [ ] [TASK-153 — Implementar notificações comerciais](TASK-153-implementar-notificacoes-comerciais.md) — Flutter Senior + Front-end
- [ ] [TASK-154 — Implementar preferências de comunicação](TASK-154-implementar-preferencias-de-comunicacao.md) — Flutter Senior + Front-end
- [ ] [TASK-155 — Implementar quiet hours](TASK-155-implementar-quiet-hours.md) — Flutter Senior + Front-end

### EPIC-20 — LGPD e Privacidade
- [ ] [TASK-156 — Implementar política de privacidade e termos](TASK-156-implementar-politica-de-privacidade.md) — Flutter Senior + Front-end
- [ ] [TASK-157 — Implementar gestão de consentimentos](TASK-157-implementar-gestao-de-consentimentos.md) — Flutter Senior + Front-end
- [ ] [TASK-158 — Implementar exportação de dados pessoais](TASK-158-implementar-exportacao-de-dados-pessoais.md) — Flutter Senior + Front-end
- [ ] [TASK-159 — Implementar exclusão de conta e dados](TASK-159-implementar-exclusao-de-conta-e-dados.md) — Flutter Senior + Front-end
- [ ] [TASK-160 — Implementar retenção configurável e minimização de dados](TASK-160-implementar-retencao-configuravel.md) — Flutter Senior

### EPIC-21 — Qualidade, Performance e Release (fim do MVP)
- [ ] [TASK-161 — Criar testes unitários da camada de domínio](TASK-161-criar-testes-unitarios-de-dominio.md) — Flutter Senior
- [ ] [TASK-162 — Criar testes de integração com Firebase Emulator](TASK-162-criar-testes-de-integracao-com-emulator.md) — Flutter Senior
- [ ] [TASK-163 — Criar testes offline e de sincronização](TASK-163-criar-testes-offline-e-sincronizacao.md) — Flutter Senior
- [ ] [TASK-164 — Otimizar performance](TASK-164-otimizar-performance.md) — Flutter Senior
- [ ] [TASK-165 — Criar pipeline CI/CD](TASK-165-criar-pipeline-ci-cd.md) — Flutter Senior
- [ ] [TASK-166 — Realizar release MVP controlado](TASK-166-realizar-release-mvp-controlado.md) — Flutter Senior

### EPIC-22 — Importação e Integrações de Dados
- [ ] [TASK-167 — Implementar importação de clientes via CSV/XLSX](TASK-167-implementar-importacao-de-clientes.md) — Flutter Senior + Front-end
- [ ] [TASK-168 — Implementar importação massiva de produtos](TASK-168-implementar-importacao-de-produtos.md) — Flutter Senior + Front-end
- [ ] [TASK-169 — Criar framework de integração com ERPs](TASK-169-criar-framework-de-integracao-erp.md) — Flutter Senior
- [ ] [TASK-170 — Implementar webhooks de saída](TASK-170-implementar-webhooks-de-saida.md) — Flutter Senior
- [ ] [TASK-171 — Implementar API pública (REST)](TASK-171-implementar-api-publica.md) — Flutter Senior
- [ ] [TASK-172 — Criar documentação OpenAPI](TASK-172-criar-documentacao-openapi.md) — Flutter Senior

### EPIC-23 — Identidade Corporativa e Internacionalização
- [ ] [TASK-173 — Implementar SSO corporativo (SAML/OIDC)](TASK-173-implementar-sso-corporativo.md) — Flutter Senior
- [ ] [TASK-174 — Implementar suporte a multi-idioma](TASK-174-implementar-suporte-multi-idioma.md) — Flutter Senior + Front-end
- [ ] [TASK-175 — Implementar suporte a multi-moeda](TASK-175-implementar-suporte-multi-moeda.md) — Flutter Senior

### EPIC-24 — Geolocalização e Roteirização
- [ ] [TASK-176 — Implementar mapa de clientes](TASK-176-implementar-mapa-de-clientes.md) — Flutter Senior + Front-end
- [ ] [TASK-177 — Implementar roteirização de visitas](TASK-177-implementar-roteirizacao-de-visitas.md) — Flutter Senior + Front-end
- [ ] [TASK-178 — Implementar check-in de visita](TASK-178-implementar-check-in-de-visita.md) — Flutter Senior + Front-end

### EPIC-25 — Catálogo Avançado e Portal B2B
- [ ] [TASK-179 — Implementar catálogo white-label](TASK-179-implementar-catalogo-white-label.md) — Flutter Senior + Front-end
- [ ] [TASK-180 — Implementar assinatura eletrônica de pedido](TASK-180-implementar-assinatura-eletronica-de-pedido.md) — Flutter Senior
- [ ] [TASK-181 — Implementar compartilhamento de carrinho/seleção](TASK-181-implementar-compartilhamento-de-carrinho.md) — Flutter Senior + Front-end
- [ ] [TASK-182 — Implementar portal B2B self-service do cliente](TASK-182-implementar-portal-b2b-do-cliente.md) — Flutter Senior + Front-end

### EPIC-26 — Comunicação Avançada
- [ ] [TASK-183 — Implementar integração WhatsApp Business](TASK-183-implementar-integracao-whatsapp-business.md) — Flutter Senior + Front-end

### EPIC-27 — Reposição e Previsão de Demanda
- [ ] [TASK-184 — Implementar sugestão de replenishment automático](TASK-184-implementar-replenishment-automatico.md) — Flutter Senior
- [ ] [TASK-185 — Implementar modelo de previsão de demanda](TASK-185-implementar-previsao-de-demanda.md) — Flutter Senior

### EPIC-28 — Inteligência Artificial Generativa
- [ ] [TASK-186 — Implementar IA generativa: resumo de carteira](TASK-186-implementar-ia-resumo-de-carteira.md) — Flutter Senior + Front-end
- [ ] [TASK-187 — Implementar IA generativa: sugestão de abordagem comercial](TASK-187-implementar-ia-sugestao-de-abordagem.md) — Flutter Senior + Front-end
- [ ] [TASK-188 — Implementar IA generativa: resumo diário do vendedor](TASK-188-implementar-ia-resumo-diario-do-vendedor.md) — Flutter Senior + Front-end
- [ ] [TASK-189 — Implementar IA generativa: explicação de relatórios](TASK-189-implementar-ia-explicacao-de-relatorios.md) — Flutter Senior + Front-end
- [ ] [TASK-190 — Implementar recomendação de produtos baseada em comportamento](TASK-190-implementar-recomendacao-comportamental.md) — Flutter Senior
- [ ] [TASK-191 — Implementar reconhecimento de produto por imagem](TASK-191-implementar-reconhecimento-de-produto-por-imagem.md) — Flutter Senior
- [ ] [TASK-192 — Implementar criação assistida de coleção/campanha (IA)](TASK-192-implementar-criacao-assistida-de-campanha.md) — Flutter Senior + Front-end

### EPIC-29 — Pagamentos e Regras Comerciais Avançadas
- [ ] [TASK-193 — Implementar integração com gateways de pagamento](TASK-193-implementar-gateways-de-pagamento.md) — Flutter Senior
- [ ] [TASK-194 — Implementar aprovação multinível de pedidos/descontos](TASK-194-implementar-aprovacao-multinivel.md) — Flutter Senior + Front-end
- [ ] [TASK-195 — Implementar comissionamento de vendedores](TASK-195-implementar-comissionamento.md) — Flutter Senior + Front-end
- [ ] [TASK-196 — Implementar políticas comerciais avançadas](TASK-196-implementar-politicas-comerciais-avancadas.md) — Flutter Senior
- [ ] [TASK-197 — Implementar orçamento (cotação) antes do pedido](TASK-197-implementar-orcamento-antes-do-pedido.md) — Flutter Senior + Front-end
- [ ] [TASK-198 — Implementar pedido recorrente](TASK-198-implementar-pedido-recorrente.md) — Flutter Senior + Front-end

### EPIC-30 — Pós-venda
- [ ] [TASK-199 — Implementar devoluções](TASK-199-implementar-devolucoes.md) — Flutter Senior + Front-end
- [ ] [TASK-200 — Implementar trocas](TASK-200-implementar-trocas.md) — Flutter Senior + Front-end
- [ ] [TASK-201 — Implementar acompanhamento de pós-venda](TASK-201-implementar-acompanhamento-de-pos-venda.md) — Flutter Senior + Front-end
- [ ] [TASK-202 — Implementar NPS e pesquisa de satisfação](TASK-202-implementar-nps.md) — Flutter Senior + Front-end

### EPIC-31 — Administração Avançada e Data Platform
- [ ] [TASK-203 — Implementar portal administrativo avançado](TASK-203-implementar-portal-administrativo-avancado.md) — Flutter Senior + Front-end
- [ ] [TASK-204 — Implementar logs de auditoria exportáveis](TASK-204-implementar-logs-de-auditoria-exportaveis.md) — Flutter Senior + Front-end
- [ ] [TASK-205 — Criar pipeline de Data Warehouse / BigQuery](TASK-205-criar-pipeline-data-warehouse.md) — Flutter Senior
- [ ] [TASK-206 — Criar camada semântica de BI](TASK-206-criar-camada-semantica-de-bi.md) — Flutter Senior

### EPIC-32 — Operações Comerciais Avançadas de Moda B2B
- [ ] [TASK-207 — Modelar kits, pacotes e sortimentos](TASK-207-modelar-kits-pacotes-e-sortimentos.md) — Flutter Senior
- [ ] [TASK-208 — Implementar venda por kit, pacote e sortimento no pedido](TASK-208-implementar-venda-por-kit-pacote-e-sortimento.md) — Flutter Senior + Front-end
- [ ] [TASK-209 — Implementar line sheet atacadista e order form por coleção](TASK-209-implementar-line-sheet-atacadista-e-order-form.md) — Flutter Senior + Front-end
- [ ] [TASK-210 — Implementar pré-venda e pre-book por coleção](TASK-210-implementar-pre-venda-e-pre-book-por-colecao.md) — Flutter Senior + Front-end
- [ ] [TASK-211 — Implementar colaboração com comprador em seleções e pedidos](TASK-211-implementar-colaboracao-com-comprador.md) — Flutter Senior + Front-end
- [ ] [TASK-212 — Implementar crédito, inadimplência e bloqueios financeiros](TASK-212-implementar-credito-inadimplencia-e-bloqueios.md) — Flutter Senior + Front-end
- [ ] [TASK-213 — Implementar contas a receber, faturas e lembretes de cobrança](TASK-213-implementar-contas-a-receber-faturas-e-cobranca.md) — Flutter Senior + Front-end
- [ ] [TASK-214 — Implementar expedição, romaneio, tracking e ocorrências](TASK-214-implementar-expedicao-romaneio-tracking-e-ocorrencias.md) — Flutter Senior + Front-end
- [ ] [TASK-215 — Implementar backorder e solicitação de estoque futuro](TASK-215-implementar-backorder-e-solicitacao-de-estoque-futuro.md) — Flutter Senior + Front-end
- [ ] [TASK-216 — Implementar leitura de código de barras e QR para venda rápida](TASK-216-implementar-leitura-de-codigo-de-barras-e-qr.md) — Flutter Senior + Front-end
- [ ] [TASK-217 — Implementar gestão de mostruário, amostras e consignação](TASK-217-implementar-gestao-de-mostruario-amostras-e-consignacao.md) — Flutter Senior + Front-end
- [ ] [TASK-218 — Implementar territórios, cobertura e potencial de carteira](TASK-218-implementar-territorios-cobertura-e-potencial-de-carteira.md) — Flutter Senior + Front-end
- [ ] [TASK-219 — Implementar ingestão de sell-out/POS do varejo](TASK-219-implementar-ingestao-de-sell-out-pos.md) — Flutter Senior
- [ ] [TASK-220 — Implementar governança de dados mestre e qualidade cadastral](TASK-220-implementar-governanca-de-dados-mestre-e-qualidade-cadastral.md) — Flutter Senior + Front-end

---

**Progresso:** 105 / 220 tasks concluídas.
