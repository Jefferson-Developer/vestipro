# VestiPro — Master Specification para Codex e Claude

> **Nota de operação:** este documento é a especificação funcional e arquitetural completa do
> produto. Para executar o backlog no dia a dia, use a versão granular e sequenciável em
> [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md) (220 tasks em 33 EPICs, cada uma com arquivo próprio
> em `docs/tasks/TASK-XXX-*.md`), seguindo o protocolo descrito em [`AGENTS.md`](AGENTS.md). A seção
> 18 abaixo ("Backlog Mestre") permanece como registro histórico do escopo original do MVP; a seção
> 19 ("Tasks adicionais recomendadas") foi incorporada ao backlog granular como EPICs 22–31, e o
> EPIC-32 adiciona a revisão final de lacunas para operações comerciais avançadas de moda B2B.

## 1. Visão do Produto

O **VestiPro** será uma plataforma omnichannel de **Força de Vendas + CRM + Catálogo de Moda + Pedidos + Inteligência Comercial + Relatórios**, criada para ser referência no mercado de moda B2B.

O produto deve funcionar em:

- iOS
- Android
- Web

A plataforma deve ser construída com foco em:

- experiência mobile-first;
- alta performance;
- operação online e offline;
- excelente usabilidade;
- design premium voltado para moda;
- escalabilidade multiempresa;
- segurança;
- analytics;
- relatórios avançados;
- insights acionáveis para vendedores;
- capacidade de crescimento para SaaS multi-tenant.

O backend será baseado prioritariamente em **Firebase**, utilizando:

- Firebase Authentication;
- Cloud Firestore;
- Firebase Storage;
- Firebase Analytics;
- Firebase Crashlytics;
- Firebase Cloud Messaging;
- Firebase Remote Config;
- Firebase App Check;
- Cloud Functions for Firebase;
- Firebase Hosting para a aplicação Web quando aplicável.

---

# 2. Objetivo Principal

Criar uma plataforma que permita que representantes, vendedores, gestores comerciais, lojistas e equipes de moda executem todo o ciclo comercial dentro de uma única solução:

1. gerenciar clientes;
2. consultar catálogo;
3. visualizar produtos, cores e grades;
4. consultar preços;
5. consultar estoque e disponibilidade;
6. criar pedidos;
7. trabalhar offline;
8. acompanhar metas;
9. acompanhar carteira de clientes;
10. registrar interações de CRM;
11. receber sugestões de venda;
12. analisar desempenho;
13. identificar oportunidades;
14. analisar mix de produtos;
15. acompanhar indicadores comerciais;
16. compartilhar catálogos;
17. gerar relatórios;
18. organizar equipe;
19. acompanhar funil de vendas;
20. administrar empresas e usuários;
21. vender por kits, pacotes e sortimentos;
22. trabalhar pré-venda/pre-book por coleção;
23. colaborar com compradores em seleções, orçamentos e pedidos;
24. controlar crédito, inadimplência, faturas e cobrança;
25. acompanhar expedição, tracking e ocorrências de entrega;
26. registrar backorders e solicitações de estoque futuro;
27. analisar sell-out/POS do varejo quando disponível;
28. governar qualidade cadastral e dados mestre.

---

# 3. Conceito de Organização e Multi-Tenancy

O VestiPro deve utilizar um modelo **multi-tenant**.

## 3.1 Organização

Ao criar a primeira conta, o usuário deve:

1. criar sua conta;
2. criar uma **Organização**;
3. tornar-se automaticamente `OWNER` da Organização;
4. poder configurar uma ou mais empresas, lojas, marcas ou unidades vinculadas.

A Organização será o tenant principal do sistema.

Exemplos:

- Organização: Grupo Fashion XPTO
- Empresas: Marca A, Marca B
- Unidades: Loja Blumenau, Loja Jaraguá, Showroom São Paulo

## 3.2 Estrutura sugerida

```text
Organization
├── Companies
│   ├── Branches
│   ├── Warehouses
│   ├── Price Lists
│   ├── Products
│   ├── Customers
│   └── Sales Orders
├── Teams
├── Users
├── Roles
└── Settings
```

## 3.3 Perfis iniciais

- OWNER
- ADMIN
- SALES_MANAGER
- SALES_REP
- SALES_ASSISTANT
- FINANCE
- READ_ONLY

O sistema deve possuir RBAC configurável.

---

# 4. Princípios Arquiteturais

## 4.1 Frontend

Tecnologia principal:

- Flutter
- Dart

Arquitetura recomendada:

- Clean Architecture
- feature-first
- separação entre presentation, application, domain e infrastructure
- BLoC/Cubit para gerenciamento de estado
- Repository Pattern
- Use Cases
- DTOs separados de Entities
- injeção de dependência
- componentes reutilizáveis
- design system centralizado

Estrutura sugerida:

```text
lib/
├── app/
├── core/
│   ├── analytics/
│   ├── auth/
│   ├── database/
│   ├── design_system/
│   ├── errors/
│   ├── extensions/
│   ├── navigation/
│   ├── network/
│   ├── offline/
│   ├── permissions/
│   ├── services/
│   ├── sync/
│   └── utils/
├── features/
│   ├── authentication/
│   ├── onboarding/
│   ├── organizations/
│   ├── users/
│   ├── crm/
│   ├── customers/
│   ├── products/
│   ├── catalog/
│   ├── inventory/
│   ├── pricing/
│   ├── orders/
│   ├── dashboards/
│   ├── reports/
│   ├── insights/
│   ├── targets/
│   ├── notifications/
│   └── settings/
└── main.dart
```

## 4.2 Backend

Utilizar Firebase como backend principal.

Cloud Functions devem encapsular regras críticas que não podem depender exclusivamente do cliente.

Nunca confiar apenas no aplicativo para:

- autorização;
- cálculo crítico de preço;
- validação de tenant;
- geração de número de pedido;
- regras financeiras;
- aprovações;
- alterações administrativas sensíveis.

---

# 5. Estratégia Offline-First

O VestiPro deve possuir operação offline real.

## 5.1 Dados disponíveis offline

O usuário deve poder baixar uma carga contendo, de acordo com sua permissão:

- clientes;
- produtos;
- variantes;
- cores;
- grades;
- tabelas de preço;
- condições de pagamento;
- estoque resumido;
- campanhas;
- pedidos recentes;
- catálogos;
- metas;
- parâmetros comerciais.

## 5.2 Banco local

Utilizar banco local apropriado ao Flutter, preferencialmente:

- Drift/SQLite, ou
- Isar se houver justificativa técnica.

A escolha deve ser documentada por ADR.

## 5.3 Sincronização

Toda entidade sincronizável deve possuir, quando aplicável:

- `id`
- `organizationId`
- `companyId`
- `createdAt`
- `createdBy`
- `updatedAt`
- `updatedBy`
- `deletedAt`
- `version`
- `syncStatus`

## 5.4 Filas offline

Operações realizadas offline devem ser persistidas em uma Outbox local.

Estados sugeridos:

- pending
- syncing
- synced
- failed
- conflict

## 5.5 Conflitos

Definir política por entidade:

- last-write-wins apenas quando seguro;
- merge por campo quando possível;
- bloqueio e resolução manual para pedidos ou informações críticas.

O sistema deve exibir conflitos de sincronização de forma compreensível.

---

# 6. Design System

O VestiPro é um produto de moda. A experiência visual deve transmitir sofisticação.

Diretrizes:

- interface clean;
- bastante espaço em branco;
- fotografias de produto valorizadas;
- tipografia forte e legível;
- cards sofisticados;
- animações discretas;
- transições suaves;
- dark mode;
- responsividade real;
- suporte a tablet;
- web desktop adaptativo;
- acessibilidade.

## 6.1 Componentes do Design System

Criar componentes reutilizáveis para:

- botões;
- inputs;
- seletores;
- dropdowns;
- chips;
- filtros;
- cards;
- tabelas;
- listas;
- badges;
- skeleton loading;
- estados vazios;
- modais;
- bottom sheets;
- snackbars;
- tooltips;
- gráficos;
- cards KPI;
- grid de produtos;
- grade de tamanhos;
- seleção de cores;
- stepper de quantidade.

---

# 7. Cadastro de Produtos

Um produto deve suportar:

- SKU;
- referência;
- nome;
- descrição curta;
- descrição completa;
- marca;
- coleção;
- estação;
- linha;
- categoria;
- subcategoria;
- gênero;
- público;
- tecido;
- composição;
- fornecedor;
- NCM;
- EAN;
- tags;
- status;
- lançamento;
- fotos;
- vídeos;
- atributos personalizados.
- vínculos com kits, pacotes e sortimentos comerciais.

## 7.1 Cores

Cada produto pode possuir N cores.

Exemplo:

```text
Camisa Essential
├── Preto
├── Branco
└── Azul Marinho
```

Cada cor pode possuir:

- código;
- nome;
- hexadecimal/RGB;
- imagem principal;
- imagens adicionais;
- disponibilidade;
- EANs próprios.

## 7.2 Grades

As grades devem ser totalmente configuráveis.

Exemplos:

```text
PP / P / M / G / GG / XGG
34 / 36 / 38 / 40 / 42 / 44 / 46
1 / 2 / 3 / 4 / 5
Único
P / M / G / G1 / G2 / G3
```

Deve ser possível criar templates de grade por organização.

Cada combinação Produto + Cor + Tamanho representa uma SKU/variante vendável.

---

# 8. CRM

O CRM deve ser integrado ao ciclo comercial.

Funcionalidades:

- carteira de clientes;
- leads;
- oportunidades;
- funil;
- tarefas;
- agenda;
- notas;
- contatos;
- histórico;
- visitas;
- follow-ups;
- lembretes;
- atividades;
- motivos de perda;
- probabilidade de fechamento;
- previsão de receita;
- segmentações;
- score do cliente;
- health score;
- próxima melhor ação.

---

# 9. Pedidos

O pedido deve suportar:

- cliente;
- endereço de entrega;
- endereço de cobrança;
- vendedor;
- empresa;
- unidade;
- tabela de preço;
- condição de pagamento;
- transportadora;
- coleção;
- tipo de pedido;
- modalidade comercial (pronta entrega, pré-venda/pre-book, backorder, pacote/sortimento);
- itens;
- quantidade por grade;
- kits, pacotes e sortimentos;
- descontos;
- acréscimos;
- frete;
- impostos quando aplicável;
- observações;
- anexos;
- status;
- aprovação;
- histórico.
- status financeiro;
- status logístico/rastreamento quando aplicável.

## 9.1 Status sugeridos

- draft
- pending_sync
- submitted
- under_review
- approved
- rejected
- processing
- invoiced
- partially_invoiced
- shipped
- delivered
- cancelled

---

# 10. Catálogo Digital

O catálogo deve possuir experiência visual de alto nível.

Modos de visualização:

- grid;
- lista;
- lookbook;
- line sheet atacadista;
- order form por coleção;
- catálogo por coleção;
- catálogo por campanha;
- pré-venda/pre-book;
- favoritos;
- novidades;
- mais vendidos;
- recomendados;
- pronta entrega.

Filtros:

- coleção;
- estação;
- marca;
- categoria;
- cor;
- tamanho;
- faixa de preço;
- disponibilidade;
- lançamento;
- tags;
- material;
- tecido;
- mais vendidos.

---

# 11. Inteligência Comercial

O VestiPro deve transformar dados em ações.

Insights possíveis:

- clientes sem compra há X dias;
- clientes com queda de faturamento;
- clientes crescendo;
- produtos com maior conversão;
- oportunidades de cross-sell;
- oportunidades de up-sell;
- produtos comprados por clientes semelhantes;
- mix abaixo do ideal;
- clientes sem determinadas categorias;
- clientes próximos da meta;
- vendedores abaixo da meta;
- pedidos abandonados;
- carrinhos salvos;
- produtos com estoque alto e giro baixo;
- produtos mais vendidos por região;
- sell-through e sell-out/POS por cliente, loja, coleção e região;
- demanda não atendida via backorder;
- potencial e cobertura de carteira por território;
- qualidade cadastral afetando confiança do insight;
- sugestão de reposição;
- sugestão de próxima visita;
- risco de churn;
- previsão de venda.

Os insights devem incluir:

- título;
- descrição;
- motivo;
- impacto estimado;
- recomendação;
- ação rápida.

---

# 12. Relatórios e BI

O módulo de relatórios deve ser uma prioridade do produto.

Inspirar-se conceitualmente em ferramentas como Salesforce, HubSpot, Power BI, Tableau, Looker e plataformas de sales analytics, sem copiar interfaces ou propriedade intelectual.

## 12.1 Dashboards

- Executive Dashboard
- Sales Dashboard
- CRM Dashboard
- Customer Dashboard
- Product Dashboard
- Collection Dashboard
- Inventory Dashboard
- Representative Dashboard
- Funnel Dashboard
- Targets Dashboard
- Geographic Dashboard

## 12.2 KPIs

- faturamento;
- quantidade vendida;
- ticket médio;
- pedidos;
- clientes ativos;
- clientes novos;
- clientes reativados;
- conversão;
- taxa de recompra;
- frequência média;
- mix médio;
- peças por pedido;
- produtos por pedido;
- desconto médio;
- margem;
- sell-through;
- fill rate;
- backorders;
- pedidos bloqueados por crédito;
- aging de contas a receber;
- OTIF/entrega no prazo;
- score de qualidade cadastral;
- crescimento YoY;
- crescimento MoM;
- atingimento de meta;
- cobertura de carteira;
- positivação;
- churn;
- previsão de fechamento;
- pipeline ponderado;
- aging do pipeline.

## 12.3 Recursos de relatório

- filtros avançados;
- comparação de período;
- drill-down;
- agrupamento;
- ordenação;
- salvar visão;
- compartilhar visão;
- exportar CSV;
- exportar XLSX;
- exportar PDF;
- agendar relatório;
- favoritos;
- relatórios customizados;
- construtor de relatórios.

---

# 13. Segurança

Obrigatório:

- RBAC;
- isolamento entre tenants;
- Firestore Security Rules;
- Storage Security Rules;
- App Check;
- validação server-side;
- logs administrativos;
- trilha de auditoria;
- soft delete onde aplicável;
- rate limiting em Functions públicas;
- princípios de least privilege;
- proteção de dados sensíveis;
- LGPD.

Nunca permitir que `organizationId` enviado pelo cliente seja a única fonte de autorização.

---

# 14. Observabilidade

Configurar:

- Firebase Crashlytics;
- Firebase Analytics;
- logs estruturados;
- métricas de sincronização;
- métricas de falhas offline;
- métricas de Functions;
- eventos comerciais relevantes;
- rastreamento de erros funcionais.

Eventos Analytics devem utilizar convenção padronizada.

Exemplos:

```text
login_completed
organization_created
customer_created
product_viewed
catalog_filtered
order_created
order_submitted
order_sync_failed
crm_activity_created
insight_opened
insight_action_clicked
report_exported
```

---

# 15. Testes

Obrigatórios:

- unit tests;
- widget tests;
- repository tests;
- use case tests;
- integration tests;
- Firebase emulator tests;
- Firestore rules tests;
- smoke tests;
- offline tests;
- synchronization tests;
- conflict tests.

Nenhuma regra de negócio crítica deve existir sem teste automatizado.

---

# 16. Regras obrigatórias para Codex e Claude

Todo agente que trabalhar no VestiPro deve seguir as regras abaixo.

## 16.1 Antes de desenvolver

1. Ler este documento por completo.
2. Identificar a task atual.
3. Verificar dependências.
4. Ler código relacionado antes de alterar.
5. Preservar padrões arquiteturais existentes.
6. Não criar soluções paralelas sem justificativa.

## 16.2 Durante o desenvolvimento

- não colocar regra de negócio em Widgets;
- não acessar Firestore diretamente pela UI;
- não usar strings mágicas;
- não duplicar código;
- não criar classes gigantes;
- não criar métodos excessivamente longos;
- não utilizar `dynamic` sem justificativa;
- não ignorar exceptions;
- não utilizar `print` em produção;
- não armazenar segredo no repositório;
- não deixar TODO sem issue/task relacionada;
- não quebrar suporte offline;
- não quebrar multi-tenancy;
- não remover testes existentes para fazer build passar.

## 16.3 Ao concluir cada task

O agente deve obrigatoriamente:

1. executar formatter;
2. executar analyzer/linter;
3. executar testes afetados;
4. adicionar novos testes;
5. atualizar documentação;
6. atualizar changelog técnico da task;
7. criar commit;
8. realizar push da branch quando houver acesso ao repositório;
9. informar arquivos criados/alterados;
10. informar testes executados;
11. registrar pendências.

Formato de commit:

```text
<tipo>(<modulo>): <descricao curta>
```

Exemplos:

```text
feat(products): add configurable size grids
feat(orders): add offline order creation
fix(sync): resolve duplicated outbox items
refactor(crm): isolate opportunity use cases
```

---

# 17. Definition of Done

Uma task somente é considerada concluída quando:

- implementação finalizada;
- arquitetura respeitada;
- UI responsiva;
- estados de loading tratados;
- estados vazios tratados;
- erros tratados;
- permissões verificadas;
- eventos Analytics adicionados quando aplicável;
- Crashlytics enriquecido quando aplicável;
- testes adicionados;
- documentação atualizada;
- linter sem erros;
- testes passando;
- commit criado.

---

# 18. Backlog Mestre

## EPIC 01 — Fundação e Arquitetura

### VESTI-001 — Inicializar projeto Flutter multiplataforma
**Objetivo:** criar projeto com suporte a iOS, Android e Web.
**Critérios de aceite:** builds mínimos funcionando nas três plataformas; flavors preparados; README inicial criado.

### VESTI-002 — Definir arquitetura feature-first + Clean Architecture
**Objetivo:** implementar estrutura base das camadas.
**Critérios de aceite:** módulos exemplo contendo presentation, application, domain e infrastructure.

### VESTI-003 — Configurar gerenciamento de estado
**Objetivo:** padronizar BLoC/Cubit.
**Critérios de aceite:** documentação com convenções e exemplo funcional.

### VESTI-004 — Configurar injeção de dependência
**Objetivo:** centralizar dependências e facilitar testes.
**Critérios de aceite:** dependências lazy/singleton/factory corretamente definidas.

### VESTI-005 — Configurar ambientes dev, staging e prod
**Objetivo:** separar Firebase e configurações.
**Critérios de aceite:** apps apontando para ambientes independentes.

### VESTI-006 — Configurar navegação principal
**Objetivo:** implementar roteamento declarativo e guards.
**Critérios de aceite:** rotas protegidas e deep links preparados.

## EPIC 02 — Firebase e Observabilidade

### VESTI-007 — Integrar Firebase Core
**Objetivo:** configurar Firebase nas três plataformas.
**Critérios de aceite:** inicialização válida em dev/staging/prod.

### VESTI-008 — Configurar Authentication
**Objetivo:** preparar login por e-mail e provedores futuros.
**Critérios de aceite:** sessão persistente e logout seguro.

### VESTI-009 — Configurar Firestore
**Objetivo:** criar infraestrutura de persistência cloud.
**Critérios de aceite:** repositories usam abstração; nenhuma UI acessa Firestore diretamente.

### VESTI-010 — Configurar Firebase Storage
**Objetivo:** suportar fotos, anexos e catálogos.
**Critérios de aceite:** upload seguro com path por tenant.

### VESTI-011 — Configurar Crashlytics
**Objetivo:** coletar crashes e erros não fatais.
**Critérios de aceite:** usuário, tenant, módulo e versão anexados quando seguro.

### VESTI-012 — Configurar Analytics
**Objetivo:** criar taxonomia e serviço central de eventos.
**Critérios de aceite:** eventos base documentados e testáveis.

## EPIC 03 — Segurança e Multi-Tenancy

### VESTI-013 — Modelar Organization
**Objetivo:** criar tenant raiz do sistema.
**Critérios de aceite:** isolamento lógico e IDs imutáveis.

### VESTI-014 — Modelar Company e Branch
**Objetivo:** permitir múltiplas empresas e unidades.
**Critérios de aceite:** vínculo obrigatório com Organization.

### VESTI-015 — Implementar RBAC
**Objetivo:** controlar funcionalidades por perfil.
**Critérios de aceite:** permissões validadas na UI e backend.

### VESTI-016 — Criar Firestore Security Rules
**Objetivo:** impedir acesso entre tenants.
**Critérios de aceite:** testes positivos e negativos no Emulator Suite.

### VESTI-017 — Criar Storage Security Rules
**Objetivo:** proteger mídias e anexos.
**Critérios de aceite:** usuário não acessa arquivos de outra organização.

### VESTI-018 — Configurar Firebase App Check
**Objetivo:** reduzir uso não autorizado dos recursos.
**Critérios de aceite:** proteção habilitada progressivamente por ambiente.

## EPIC 04 — Autenticação e Onboarding

### VESTI-019 — Tela de login
**Objetivo:** autenticação elegante e responsiva.
**Critérios de aceite:** loading, erros, acessibilidade e analytics.

### VESTI-020 — Cadastro inicial
**Objetivo:** cadastrar usuário e iniciar onboarding.
**Critérios de aceite:** validações completas e termos aceitos.

### VESTI-021 — Recuperação de senha
**Objetivo:** permitir reset seguro.
**Critérios de aceite:** fluxo completo e feedback visual.

### VESTI-022 — Criação da primeira Organization
**Objetivo:** tornar usuário criador em OWNER.
**Critérios de aceite:** operação transacional/idempotente.

### VESTI-023 — Wizard de configuração inicial
**Objetivo:** configurar nome, segmento, moeda, país e preferências.
**Critérios de aceite:** progresso salvo e retomável.

### VESTI-024 — Convite de usuários
**Objetivo:** OWNER/ADMIN convidar colaboradores.
**Critérios de aceite:** convite com expiração, função e organização definidas.

## EPIC 05 — Gestão de Usuários e Equipes

### VESTI-025 — Lista de usuários
**Objetivo:** administrar membros da organização.
**Critérios de aceite:** busca, filtro, paginação e status.

### VESTI-026 — Gestão de perfis e permissões
**Objetivo:** alterar role dos usuários autorizados.
**Critérios de aceite:** auditoria de alterações.

### VESTI-027 — Criar equipes comerciais
**Objetivo:** agrupar vendedores e gestores.
**Critérios de aceite:** usuário pode pertencer a equipes permitidas.

### VESTI-028 — Vincular vendedores a carteiras
**Objetivo:** definir responsabilidade por clientes.
**Critérios de aceite:** cobertura e regras de visibilidade funcionando.

### VESTI-029 — Desativar usuário
**Objetivo:** remover acesso preservando histórico.
**Critérios de aceite:** dados históricos continuam íntegros.

### VESTI-030 — Auditoria de acessos administrativos
**Objetivo:** registrar ações sensíveis.
**Critérios de aceite:** log imutável com ator, data e ação.

## EPIC 06 — Clientes

### VESTI-031 — Modelar Customer
**Objetivo:** criar entidade completa de cliente.
**Critérios de aceite:** suporta pessoa jurídica e física quando necessário.

### VESTI-032 — Cadastro de cliente
**Objetivo:** implementar formulário completo.
**Critérios de aceite:** campos obrigatórios configuráveis e validação.

### VESTI-033 — Endereços e contatos
**Objetivo:** cadastrar múltiplos contatos e endereços.
**Critérios de aceite:** endereço principal e tipos configuráveis.

### VESTI-034 — Carteira de clientes
**Objetivo:** listar clientes do representante.
**Critérios de aceite:** filtros por status, região, potencial e última compra.

### VESTI-035 — Detalhe do cliente 360º
**Objetivo:** consolidar histórico comercial e CRM.
**Critérios de aceite:** pedidos, atividades, indicadores e oportunidades visíveis.

### VESTI-036 — Segmentação de clientes
**Objetivo:** criar segmentos dinâmicos.
**Critérios de aceite:** filtros persistidos e reutilizáveis.

## EPIC 07 — CRM

### VESTI-037 — Leads
**Objetivo:** cadastrar e qualificar leads.
**Critérios de aceite:** origem, responsável, score e status.

### VESTI-038 — Oportunidades
**Objetivo:** registrar negociações potenciais.
**Critérios de aceite:** valor, probabilidade, previsão e responsável.

### VESTI-039 — Funil de vendas
**Objetivo:** criar pipeline configurável.
**Critérios de aceite:** drag-and-drop na Web quando aplicável e alternativa mobile.

### VESTI-040 — Atividades CRM
**Objetivo:** registrar ligação, visita, reunião, mensagem e nota.
**Critérios de aceite:** timeline cronológica completa.

### VESTI-041 — Tarefas e follow-ups
**Objetivo:** controlar próximas ações.
**Critérios de aceite:** vencimento, prioridade, responsável e conclusão.

### VESTI-042 — Motivos de perda e ganho
**Objetivo:** gerar aprendizado comercial.
**Critérios de aceite:** catálogo configurável de motivos e relatórios associados.

## EPIC 08 — Produtos e Catálogo Base

### VESTI-043 — Modelar Product
**Objetivo:** suportar atributos completos de moda.
**Critérios de aceite:** campos padrão e custom fields.

### VESTI-044 — Cadastro de produto
**Objetivo:** formulário administrativo completo.
**Critérios de aceite:** criação, edição, validação e auditoria.

### VESTI-045 — Coleções e estações
**Objetivo:** organizar produtos por calendário de moda.
**Critérios de aceite:** associação múltipla quando permitida.

### VESTI-046 — Categorias e subcategorias
**Objetivo:** organizar catálogo hierarquicamente.
**Critérios de aceite:** árvore configurável.

### VESTI-047 — Fotos e vídeos de produto
**Objetivo:** administrar mídia no Storage.
**Critérios de aceite:** compressão, thumbnails e ordenação.

### VESTI-048 — Busca global de produtos
**Objetivo:** localizar por nome, SKU, referência, EAN e tags.
**Critérios de aceite:** busca rápida online e offline.

## EPIC 09 — Cores, Grades e Variantes

### VESTI-049 — Cadastro de cores
**Objetivo:** criar paleta reutilizável.
**Critérios de aceite:** código, nome, RGB/HEX e status.

### VESTI-050 — Templates de grade
**Objetivo:** permitir grades customizadas.
**Critérios de aceite:** tamanhos ordenáveis e reutilizáveis.

### VESTI-051 — Variantes de produto
**Objetivo:** gerar combinações produto-cor-tamanho.
**Critérios de aceite:** SKU e EAN independentes por variante.

### VESTI-052 — UI de grade comercial
**Objetivo:** permitir digitação de quantidades por tamanho.
**Critérios de aceite:** navegação rápida, teclado adequado e totais.

### VESTI-053 — Disponibilidade por variante
**Objetivo:** exibir estoque por cor/tamanho.
**Critérios de aceite:** diferencia pronta entrega, futuro e indisponível.

### VESTI-054 — Ordenação personalizada de tamanhos
**Objetivo:** preservar ordem comercial da grade.
**Critérios de aceite:** templates definem score/ordem explícita.

## EPIC 10 — Catálogo Premium

### VESTI-055 — Home do catálogo
**Objetivo:** destacar coleções, lançamentos e oportunidades.
**Critérios de aceite:** layout premium e responsivo.

### VESTI-056 — Grid visual de produtos
**Objetivo:** exibir cards com foco em imagem.
**Critérios de aceite:** skeleton, lazy load e cache.

### VESTI-057 — Detalhe visual de produto
**Objetivo:** criar experiência completa de compra B2B.
**Critérios de aceite:** galeria, cores, grades, preços e estoque.

### VESTI-058 — Favoritos
**Objetivo:** salvar produtos para consulta posterior.
**Critérios de aceite:** disponível online e offline.

### VESTI-059 — Lookbook e campanhas
**Objetivo:** criar narrativas visuais por coleção.
**Critérios de aceite:** conteúdo configurável via admin.

### VESTI-060 — Compartilhamento de catálogo
**Objetivo:** compartilhar produtos/seleções com clientes.
**Critérios de aceite:** link controlado e analytics de abertura quando possível.

## EPIC 11 — Tabelas de Preço e Condições Comerciais

### VESTI-061 — Modelar Price List
**Objetivo:** permitir múltiplas tabelas.
**Critérios de aceite:** validade, moeda e escopo por empresa.

### VESTI-062 — Preço por produto/variante
**Objetivo:** cadastrar preços específicos.
**Critérios de aceite:** fallback documentado e consistente.

### VESTI-063 — Condições de pagamento
**Objetivo:** configurar regras comerciais.
**Critérios de aceite:** status, parcelas e prazo médio.

### VESTI-064 — Políticas de desconto
**Objetivo:** controlar limites por perfil.
**Critérios de aceite:** desconto acima do limite gera bloqueio/aprovação.

### VESTI-065 — Campanhas promocionais
**Objetivo:** aplicar promoções por período e segmento.
**Critérios de aceite:** regras reproduzíveis e auditáveis.

### VESTI-066 — Motor de precificação server-side
**Objetivo:** centralizar cálculo crítico.
**Critérios de aceite:** Cloud Function idempotente e testada.

## EPIC 12 — Estoque e Disponibilidade

### VESTI-067 — Modelar Warehouse
**Objetivo:** representar depósitos e unidades.
**Critérios de aceite:** vínculo com company/branch.

### VESTI-068 — Saldo por variante
**Objetivo:** armazenar disponibilidade vendável.
**Critérios de aceite:** consultas eficientes e atualização incremental.

### VESTI-069 — Estoque futuro
**Objetivo:** suportar previsão de disponibilidade.
**Critérios de aceite:** data prevista exibida ao vendedor.

### VESTI-070 — Reserva comercial
**Objetivo:** preparar estrutura para reservas temporárias.
**Critérios de aceite:** feature flag e regras server-side.

### VESTI-071 — Alertas de ruptura
**Objetivo:** informar baixa disponibilidade.
**Critérios de aceite:** thresholds configuráveis.

### VESTI-072 — Giro de estoque
**Objetivo:** gerar indicadores de sell-through e cobertura.
**Critérios de aceite:** dados disponíveis para relatórios e insights.

## EPIC 13 — Pedidos

### VESTI-073 — Criar pedido em rascunho
**Objetivo:** iniciar venda associada a cliente.
**Critérios de aceite:** funciona online e offline.

### VESTI-074 — Adicionar produtos via catálogo
**Objetivo:** inserir variantes e quantidades.
**Critérios de aceite:** atualização de totais em tempo real.

### VESTI-075 — Tela de grade no pedido
**Objetivo:** agilizar venda por cor/tamanho.
**Critérios de aceite:** total por cor, tamanho e produto.

### VESTI-076 — Resumo comercial do pedido
**Objetivo:** exibir subtotal, desconto, frete e total.
**Critérios de aceite:** cálculo compatível com motor de precificação.

### VESTI-077 — Validações antes do envio
**Objetivo:** impedir pedidos inconsistentes.
**Critérios de aceite:** cliente, preço, quantidade, condição e permissões validados.

### VESTI-078 — Submissão do pedido
**Objetivo:** enviar pedido para processamento.
**Critérios de aceite:** idempotência, número único e trilha de status.

## EPIC 14 — Offline e Sincronização

### VESTI-079 — Escolher e configurar banco local
**Objetivo:** implantar persistência offline.
**Critérios de aceite:** ADR comparando Drift/SQLite e alternativas.

### VESTI-080 — Criar pacote de carga offline
**Objetivo:** permitir download dos dados essenciais.
**Critérios de aceite:** progresso, tamanho estimado e cancelamento seguro.

### VESTI-081 — Implementar Outbox
**Objetivo:** persistir operações pendentes.
**Critérios de aceite:** operações sobrevivem a fechamento do app.

### VESTI-082 — Motor de sincronização incremental
**Objetivo:** sincronizar apenas alterações.
**Critérios de aceite:** cursor/versionamento, retry e backoff.

### VESTI-083 — Resolução de conflitos
**Objetivo:** tratar concorrência de alterações.
**Critérios de aceite:** políticas por entidade e tela de conflito quando necessária.

### VESTI-084 — Central de sincronização
**Objetivo:** dar transparência ao usuário.
**Critérios de aceite:** última sincronização, pendências, falhas e retry.

## EPIC 15 — Metas e Performance Comercial

### VESTI-085 — Cadastro de metas
**Objetivo:** criar metas por período e dimensão.
**Critérios de aceite:** vendedor, equipe, empresa, coleção e categoria.

### VESTI-086 — Dashboard de atingimento
**Objetivo:** acompanhar progresso em tempo real.
**Critérios de aceite:** realizado, meta, gap e projeção.

### VESTI-087 — Positivação de carteira
**Objetivo:** medir clientes comprando no período.
**Critérios de aceite:** regras de carteira configuráveis.

### VESTI-088 — Ranking comercial
**Objetivo:** comparar vendedores/equipes.
**Critérios de aceite:** permissão impede exposição indevida.

### VESTI-089 — Projeção de fechamento
**Objetivo:** estimar resultado do período.
**Critérios de aceite:** metodologia documentada.

### VESTI-090 — Alertas de meta
**Objetivo:** sinalizar risco ou oportunidade.
**Critérios de aceite:** thresholds configuráveis e sem excesso de notificações.

## EPIC 16 — Insights e Recomendação

### VESTI-091 — Engine base de insights
**Objetivo:** criar framework extensível de regras.
**Critérios de aceite:** cada insight possui evidência e ação.

### VESTI-092 — Insight de cliente inativo
**Objetivo:** detectar ausência de compra.
**Critérios de aceite:** janela configurável e ação de contato.

### VESTI-093 — Insight de queda de faturamento
**Objetivo:** detectar retração relevante.
**Critérios de aceite:** comparação de períodos equivalentes.

### VESTI-094 — Insight de cross-sell
**Objetivo:** sugerir categorias ausentes.
**Critérios de aceite:** explicação da recomendação.

### VESTI-095 — Insight de mix insuficiente
**Objetivo:** comparar mix do cliente com benchmark.
**Critérios de aceite:** benchmark parametrizável.

### VESTI-096 — Central de oportunidades
**Objetivo:** reunir insights priorizados.
**Critérios de aceite:** prioridade, impacto e ação rápida.

## EPIC 17 — Dashboards e Relatórios

### VESTI-097 — Dashboard executivo
**Objetivo:** visão geral da operação.
**Critérios de aceite:** KPIs, tendências e filtros globais.

### VESTI-098 — Dashboard de vendas
**Objetivo:** analisar pedidos e faturamento.
**Critérios de aceite:** comparação temporal e drill-down.

### VESTI-099 — Dashboard de clientes
**Objetivo:** analisar carteira, retenção e ativação.
**Critérios de aceite:** segmentações e ranking.

### VESTI-100 — Dashboard de produtos
**Objetivo:** analisar mix, giro e desempenho.
**Critérios de aceite:** coleção, cor, tamanho e categoria.

### VESTI-101 — Dashboard de CRM
**Objetivo:** analisar pipeline e atividades.
**Critérios de aceite:** conversão por etapa e aging.

### VESTI-102 — Dashboard de metas
**Objetivo:** analisar performance versus objetivo.
**Critérios de aceite:** filtros por equipe, vendedor e período.

## EPIC 18 — Relatórios Customizados e Exportações

### VESTI-103 — Construtor de relatórios
**Objetivo:** permitir escolha de dimensões, métricas e filtros.
**Critérios de aceite:** validações impedem consultas inválidas.

### VESTI-104 — Salvar visualizações
**Objetivo:** persistir relatórios favoritos.
**Critérios de aceite:** privado ou compartilhado conforme permissão.

### VESTI-105 — Exportação CSV
**Objetivo:** exportar dados tabulares.
**Critérios de aceite:** encoding, grandes volumes e nomes consistentes.

### VESTI-106 — Exportação XLSX
**Objetivo:** gerar planilhas formatadas.
**Critérios de aceite:** cabeçalhos, tipos e filtros básicos.

### VESTI-107 — Exportação PDF
**Objetivo:** gerar relatórios executivos.
**Critérios de aceite:** layout profissional e branding da organização.

### VESTI-108 — Agendamento de relatórios
**Objetivo:** preparar envio periódico.
**Critérios de aceite:** Cloud Functions/Cloud Scheduler e permissões adequadas.

## EPIC 19 — Notificações e Engajamento

### VESTI-109 — Firebase Cloud Messaging
**Objetivo:** habilitar push notification.
**Critérios de aceite:** token lifecycle e opt-in tratados.

### VESTI-110 — Central de notificações
**Objetivo:** listar alertas internos.
**Critérios de aceite:** lidas/não lidas, categorias e deep link.

### VESTI-111 — Notificações de CRM
**Objetivo:** lembrar atividades e follow-ups.
**Critérios de aceite:** horários configuráveis.

### VESTI-112 — Notificações comerciais
**Objetivo:** alertar sobre metas, pedidos e oportunidades.
**Critérios de aceite:** preferências por categoria.

### VESTI-113 — Preferências de comunicação
**Objetivo:** controlar canais e frequência.
**Critérios de aceite:** alterações sincronizadas por usuário.

### VESTI-114 — Quiet hours
**Objetivo:** evitar notificações em horários inadequados.
**Critérios de aceite:** timezone respeitado.

## EPIC 20 — Qualidade, Performance e Release

### VESTI-115 — Testes unitários da camada de domínio
**Objetivo:** proteger regras críticas.
**Critérios de aceite:** cobertura dos principais use cases.

### VESTI-116 — Testes de integração com Firebase Emulator
**Objetivo:** validar Functions e Rules.
**Critérios de aceite:** pipeline automatizado.

### VESTI-117 — Testes offline e sincronização
**Objetivo:** validar cenários reais sem internet.
**Critérios de aceite:** criação, edição, conflito e reconexão.

### VESTI-118 — Otimização de performance
**Objetivo:** reduzir jank, leituras e uso de memória.
**Critérios de aceite:** métricas antes/depois documentadas.

### VESTI-119 — Pipeline CI/CD
**Objetivo:** automatizar análise, testes e builds.
**Critérios de aceite:** PR bloqueada quando quality gates falham.

### VESTI-120 — Release MVP controlado
**Objetivo:** consolidar primeira versão utilizável.
**Critérios de aceite:** checklist de segurança, observabilidade, testes, documentação e rollback.

---

# 19. Tasks adicionais recomendadas para evolução pós-MVP

Após VESTI-120, considerar:

- importação de clientes via CSV/XLSX;
- importação massiva de produtos;
- integrações ERP;
- webhooks;
- API pública;
- OpenAPI;
- SSO corporativo;
- multi-moeda;
- multi-idioma;
- mapa de clientes;
- roteirização de visitas;
- check-in de visita;
- geolocalização opcional;
- catálogo white-label;
- assinatura eletrônica de pedido;
- integração WhatsApp Business;
- compartilhamento de carrinho;
- portal B2B do cliente;
- replenishment automático;
- previsão de demanda;
- IA generativa para resumo de carteira;
- IA para sugestão de abordagem;
- IA para resumo diário do vendedor;
- IA para explicar relatórios;
- recomendação de produtos baseada em comportamento;
- reconhecimento de produto por imagem;
- criação assistida de coleção/campanha;
- integração com gateways de pagamento;
- aprovação multinível;
- comissionamento;
- políticas comerciais avançadas;
- orçamento antes do pedido;
- pedido recorrente;
- devoluções;
- trocas;
- pós-venda;
- NPS;
- portal administrativo avançado;
- logs de auditoria exportáveis;
- Data Warehouse/BigQuery;
- camada semântica de BI;
- kits, pacotes e sortimentos;
- venda por kit/pacote/sortimento no pedido;
- line sheet atacadista e order form por coleção;
- pré-venda/pre-book por coleção;
- colaboração com comprador em seleções e pedidos;
- crédito, inadimplência e bloqueios financeiros;
- contas a receber, faturas e lembretes de cobrança;
- expedição, romaneio, tracking e ocorrências;
- backorder e solicitação de estoque futuro;
- leitura de código de barras/QR para venda rápida;
- gestão de mostruário, amostras e consignação;
- territórios, cobertura e potencial de carteira;
- ingestão de sell-out/POS do varejo;
- governança de dados mestre e qualidade cadastral.

---

# 20. Modelo inicial de Collections do Firestore

Estrutura sugerida conceitualmente:

```text
organizations/{organizationId}
organizations/{organizationId}/companies/{companyId}
organizations/{organizationId}/branches/{branchId}
organizations/{organizationId}/members/{userId}
organizations/{organizationId}/teams/{teamId}
organizations/{organizationId}/roles/{roleId}
organizations/{organizationId}/customers/{customerId}
organizations/{organizationId}/leads/{leadId}
organizations/{organizationId}/opportunities/{opportunityId}
organizations/{organizationId}/activities/{activityId}
organizations/{organizationId}/products/{productId}
organizations/{organizationId}/products/{productId}/colors/{colorId}
organizations/{organizationId}/products/{productId}/variants/{variantId}
organizations/{organizationId}/sizeGrids/{gridId}
organizations/{organizationId}/collections/{collectionId}
organizations/{organizationId}/priceLists/{priceListId}
organizations/{organizationId}/warehouses/{warehouseId}
organizations/{organizationId}/inventory/{inventoryId}
organizations/{organizationId}/commercialPacks/{packId}
organizations/{organizationId}/lineSheets/{lineSheetId}
organizations/{organizationId}/preBookPrograms/{programId}
organizations/{organizationId}/orders/{orderId}
organizations/{organizationId}/backorders/{backorderId}
organizations/{organizationId}/buyerCollaborations/{sessionId}
organizations/{organizationId}/creditProfiles/{customerId}
organizations/{organizationId}/receivables/{receivableId}
organizations/{organizationId}/shipments/{shipmentId}
organizations/{organizationId}/sampleKits/{sampleKitId}
organizations/{organizationId}/territories/{territoryId}
organizations/{organizationId}/sellOutEvents/{eventId}
organizations/{organizationId}/dataQualityIssues/{issueId}
organizations/{organizationId}/targets/{targetId}
organizations/{organizationId}/insights/{insightId}
organizations/{organizationId}/savedReports/{reportId}
organizations/{organizationId}/notifications/{notificationId}
organizations/{organizationId}/auditLogs/{logId}
```

A estrutura definitiva deve ser validada levando em conta:

- padrão de consultas;
- custo de leitura;
- limites do Firestore;
- índices;
- segurança;
- volume;
- sincronização offline.

Não criar subcollections apenas por organização visual. Modelar a partir das consultas reais.

---

# 21. Padrão de Entidade

Exemplo conceitual:

```text
id
organizationId
companyId
status
createdAt
createdBy
updatedAt
updatedBy
deletedAt
version
```

Campos de auditoria devem ser preenchidos no backend sempre que possível.

---

# 22. Índices e Performance Firestore

Antes de implementar consultas de alto volume:

1. definir filtros;
2. definir ordenação;
3. avaliar índices compostos;
4. avaliar paginação por cursor;
5. evitar documentos gigantes;
6. evitar arrays sem limite;
7. evitar fan-out desnecessário;
8. medir quantidade de reads;
9. documentar estratégia de cache;
10. considerar agregações pré-calculadas.

Dashboards complexos não devem executar centenas de consultas do cliente.

Criar snapshots/agregações server-side quando necessário.

---

# 23. Estratégia de Analytics de Produto

Além de Analytics técnico, rastrear funil de uso:

```text
signup_started
signup_completed
onboarding_completed
first_customer_created
first_product_created
first_order_created
first_order_submitted
offline_pack_downloaded
catalog_opened
product_viewed
product_added_to_order
order_abandoned
order_submitted
crm_followup_completed
insight_viewed
insight_converted
report_opened
report_exported
```

Nunca enviar dados pessoais sensíveis em parâmetros de Analytics.

---

# 24. Home do Representante

A Home deve responder rapidamente:

- quanto vendi hoje;
- quanto vendi no mês;
- quanto falta para minha meta;
- quais clientes devo contatar;
- quais oportunidades estão paradas;
- quais pedidos possuem problema;
- quais produtos estão vendendo mais;
- quais clientes estão sem comprar;
- quais ações devo executar agora.

Cards sugeridos:

- Venda do mês
- Atingimento de meta
- Pedidos recentes
- Clientes para visitar
- Follow-ups de hoje
- Oportunidades quentes
- Insights prioritários
- Novidades da coleção

---

# 25. Home do Gestor

A Home do gestor deve priorizar:

- faturamento;
- atingimento geral;
- performance por vendedor;
- performance por região;
- performance por coleção;
- vendedores em risco;
- clientes em risco;
- pipeline;
- previsão de fechamento;
- principais produtos;
- gargalos de pedidos.

---

# 26. Experiência Mobile

O fluxo deve permitir que um representante realize venda com poucos toques.

Requisitos:

- pesquisa sempre rápida;
- ações principais acessíveis com uma mão;
- teclado numérico inteligente na grade;
- salvar automaticamente rascunhos;
- preservar estado ao trocar de tela;
- feedback visual de sincronização;
- evitar diálogos excessivos;
- suportar tablets com layouts de duas colunas.

---

# 27. Experiência Web

Na Web, aproveitar espaço adicional:

- sidebar;
- tabelas densas;
- filtros laterais;
- múltiplas colunas;
- atalhos de teclado;
- drag-and-drop quando adequado;
- dashboards amplos;
- construtor de relatórios.

A Web não deve ser apenas uma versão mobile esticada.

---

# 28. LGPD

Implementar:

- política de privacidade;
- termos;
- consentimentos quando aplicável;
- minimização de dados;
- exportação de dados quando aplicável;
- exclusão conforme obrigação legal;
- registro de consentimento;
- retenção configurável;
- auditoria de acesso administrativo.

---

# 29. Roadmap sugerido

## Fase 1 — Fundação
VESTI-001 a VESTI-030

## Fase 2 — Core Comercial
VESTI-031 a VESTI-078

## Fase 3 — Offline e Inteligência
VESTI-079 a VESTI-096

## Fase 4 — BI e Engajamento
VESTI-097 a VESTI-114

## Fase 5 — Hardening e Release
VESTI-115 a VESTI-120

## Fase 6 — Operações comerciais avançadas
TASK-207 a TASK-220

---

# 30. Prioridade sugerida para MVP

Para um primeiro MVP comercial, priorizar:

1. autenticação;
2. organização;
3. usuários;
4. clientes;
5. produtos;
6. cores;
7. grades;
8. catálogo;
9. tabelas de preço;
10. pedidos;
11. offline;
12. sincronização;
13. CRM básico;
14. dashboard comercial;
15. Crashlytics;
16. Analytics;
17. segurança;
18. relatórios essenciais.

Recursos avançados de IA podem entrar depois que houver volume de dados suficiente.

---

# 31. Instrução final aos agentes

Ao receber uma task do VestiPro:

1. localizar o ID da task neste documento;
2. verificar dependências técnicas e funcionais;
3. analisar o código existente antes de alterar;
4. implementar a solução completa;
5. não criar atalhos técnicos que prejudiquem escalabilidade;
6. manter compatibilidade iOS, Android e Web;
7. validar comportamento offline quando o módulo permitir operação offline;
8. manter isolamento multi-tenant;
9. criar testes;
10. atualizar documentação;
11. executar análise estática;
12. executar testes;
13. criar commit;
14. realizar push quando autorizado;
15. retornar um relatório final da execução.

O relatório final deve conter:

```text
Task:
Status:
Resumo:
Arquivos criados:
Arquivos alterados:
Testes criados:
Testes executados:
Resultado dos testes:
Decisões arquiteturais:
Analytics adicionados:
Impacto offline:
Impacto Firebase:
Pendências:
Commit:
```

O objetivo não é apenas fazer a funcionalidade funcionar. O objetivo é construir uma base capaz de sustentar o **maior aplicativo mobile de força de vendas especializado em moda**, com qualidade de produto SaaS de nível internacional.
