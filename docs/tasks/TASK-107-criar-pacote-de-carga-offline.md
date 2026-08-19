# TASK-107 — Criar pacote de carga offline

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-106 (schema Drift criado — a carga grava diretamente nas tabelas locais)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar o fluxo de seleção e download inicial dos dados essenciais para operação offline (seção 5.1 de `tasks.md`), respeitando a permissão/carteira do usuário, com progresso visível, tamanho estimado e cancelamento seguro que nunca corrompe dados parciais no banco local.

## Escopo técnico

- Criar `DownloadOfflinePackageUseCase` orquestrando a seleção dos dados conforme RBAC/carteira do usuário: clientes da carteira do vendedor (ou todos, para gestor/admin), produtos e variantes ativos, tabelas de preço vigentes aplicáveis ao usuário, estoque resumido, catálogos publicados e metas do usuário/equipe.
- Implementar download em lotes (paginação/streaming), gravando cada lote em uma transação Drift, em vez de carregar toda a carga em memória de uma só vez.
- Calcular e exibir o tamanho estimado da carga antes de iniciar (baseado em contagem de documentos/tamanho médio estimado) e progresso incremental durante o download (ex.: "3.200 / 12.000 registros").
- Implementar cancelamento seguro: ao cancelar, apenas os lotes ainda não commitados são descartados (a transação por lote garante que um cancelamento no meio não deixe tabela em estado parcialmente inconsistente); persistir um marcador de "carga incompleta" que impede o app de assumir que os dados offline estão completos até uma nova carga bem-sucedida.
- Registrar o timestamp da última carga completa por entidade, para uso posterior pela Central de Sincronização (TASK-112).
- Expor o estado via BLoC/Cubit (`OfflinePackageDownloadCubit`) com estados: idle, estimating, downloading(progress), cancelled, completed, failed.

## Regras de negócio e restrições

- Um `SALES_REP` só baixa clientes da própria carteira e produtos/tabelas de preço aos quais tem acesso; `SALES_MANAGER`/`ADMIN` podem baixar uma carga mais ampla conforme o RBAC definido na TASK-029.
- Cancelamento nunca pode deixar o banco local em estado que o app interprete como "dados completos e confiáveis" — o marcador de carga incompleta é obrigatório.
- O download deve poder ser retomado (não necessariamente do zero) quando a conexão cair no meio, sempre que tecnicamente viável por lote.
- Nunca baixar dados de outra organização/empresa — toda consulta remota usada aqui é escopada pelo `organizationId`/`companyId` do usuário autenticado.

## Testes obrigatórios

- Teste do caso de uso cobrindo: carga completa com sucesso, cancelamento no meio (nenhum dado parcial de lote não commitado permanece), falha de rede no meio da carga (estado `failed`, dados de lotes já commitados preservados).
- Teste verificando que o RBAC filtra corretamente o conjunto de clientes/produtos baixados por perfil (`SALES_REP` vs. `SALES_MANAGER`).
- Teste do cálculo de tamanho/progresso estimado.
- Teste de retomada de uma carga interrompida.

## Critérios de aceite

- Usuário consegue baixar a carga offline com barra de progresso e tamanho estimado visíveis.
- Cancelamento não corrompe dados de lotes já sincronizados anteriormente.
- Carga respeita RBAC/carteira do usuário.
- `flutter analyze` e `flutter test` passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
