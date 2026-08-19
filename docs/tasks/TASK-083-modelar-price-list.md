# TASK-083 — Modelar Price List

**Epic:** EPIC-11 — Tabelas de Preço e Condições Comerciais
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (modelagem de Organization, fonte do escopo multi-tenant de toda Price List)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade `PriceList` (tabela de preço), fundação de todo o EPIC-11, suportando múltiplas
tabelas ativas simultaneamente (por empresa, canal, segmento de cliente ou período), com validade e
moeda definidas — sem essa base, preço por variante, condição de pagamento, política de desconto,
campanha e motor de precificação não têm onde se apoiar.

## Escopo técnico

- Definir entidade de domínio `PriceList` (`id`, `organizationId`, `companyId`, `name`, `currency`,
  `validFrom`, `validTo`, `status` [rascunho/ativa/expirada/arquivada], `scope` [empresa/canal/
  segmento], `priority` para desempate entre tabelas aplicáveis ao mesmo cliente).
- Criar DTO (`PriceListDto`), mapper e repositório (`PriceListRepository`) seguindo Clean
  Architecture (contrato em `domain/repositories`, implementação em `data/repositories`).
- Modelar coleção Firestore `companies/{companyId}/priceLists/{priceListId}` (ou estrutura
  equivalente compatível com o padrão de consultas do projeto — ver `tasks.md`, seções 20/22),
  evitando documentos gigantes.
- Implementar caso de uso `ResolveApplicablePriceListsUseCase` que retorna as tabelas vigentes e
  aplicáveis a um cliente/pedido em um instante, considerando validade e prioridade — usado depois
  pelo motor de precificação (TASK-088).
- Persistir Price Lists localmente (Drift) como parte da carga offline do catálogo, com
  `syncStatus` e estratégia de atualização incremental.
- Criar Firestore Security Rules garantindo leitura escopada por organização/empresa e escrita
  restrita a perfis administrativos (`OWNER`, `ADMIN`, `FINANCE`), com teste positivo e negativo no
  Emulator Suite.

## Regras de negócio e restrições

- Mais de uma Price List pode estar ativa ao mesmo tempo para a mesma organização/empresa; a
  resolução de qual tabela vale para um cliente/pedido específico é responsabilidade do domínio
  (via `priority`/escopo), nunca da UI.
- Tabela fora do período de vigência (`validFrom`/`validTo`) nunca pode ser retornada como
  aplicável, mesmo que ainda exista no banco.
- Moeda da tabela é imutável após uso em qualquer pedido (trocar moeda de uma tabela em uso exige
  criar uma nova tabela, não editar a existente).
- Toda leitura de Price List é escopada por organização/empresa ativa — nunca depender de o cliente
  "lembrar" de filtrar.

## Testes obrigatórios

- Testes de domínio/mapper: criação de `PriceList` válida, validação de datas inconsistentes
  (`validTo` anterior a `validFrom`), moeda ausente, escopo ausente.
- Testes do caso de uso `ResolveApplicablePriceListsUseCase`: nenhuma tabela vigente, uma tabela
  vigente, múltiplas tabelas vigentes com prioridades diferentes, tabela expirada excluída do
  resultado, tabela agendada (ainda não iniciada) excluída do resultado.
- Testes de repositório local (Drift): inserção, atualização incremental, leitura offline.
- Testes de Firestore Security Rules: leitura permitida dentro da organização/empresa, leitura
  negada para organização diferente, escrita permitida para `ADMIN`/`FINANCE`, escrita negada para
  `SALES_REP`.

## Critérios de aceite

- Entidade, DTO, mapper e repositório de `PriceList` implementados e testados conforme a
  arquitetura Clean/feature-first do projeto.
- Múltiplas tabelas de preço podem coexistir ativas para a mesma empresa, com resolução de
  aplicabilidade correta por vigência e prioridade.
- Regras de segurança do Firestore aprovadas no Emulator Suite (teste positivo e negativo).
- Carga offline de Price Lists funcional, com sincronização incremental.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
