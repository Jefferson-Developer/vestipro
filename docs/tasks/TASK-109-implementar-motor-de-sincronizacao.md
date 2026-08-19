# TASK-109 — Implementar motor de sincronização incremental

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-108 (Outbox implementada — o motor processa a fila e também aplica mudanças remotas)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar o motor que sincroniza apenas as alterações (não a base inteira) entre o banco local e o Firestore, processando a Outbox em background com retry e backoff exponencial, garantindo idempotência para nunca duplicar dados em reenvios.

## Escopo técnico

- Implementar `SyncEngine` com dois fluxos: push (drena a Outbox, item a item, respeitando ordem, enviando para Cloud Functions/Firestore) e pull (busca apenas documentos alterados desde o último cursor/timestamp/version por coleção, usando um campo de cursor persistido por entidade em uma `SyncCursorsTable`).
- Implementar retry com backoff exponencial (ex.: 2s, 4s, 8s... até um teto configurável) e limite de tentativas antes de marcar a operação como `failed` e notificar a Central de Sincronização (TASK-112).
- Rodar o processamento da Outbox em background (ex.: listener de conectividade via `connectivity_plus` + trigger quando o app volta ao foreground), sem bloquear a UI.
- Garantir idempotência: cada operação da Outbox carrega um `clientOperationId` único; o backend (Cloud Function) deve poder recusar/ignorar reprocessamento do mesmo `clientOperationId` (contrato a alinhar com a camada de Functions), e o motor local trata uma resposta de "já processado" como sucesso, sem reenfileirar.
- Implementar pull incremental por versão/cursor: nunca refazer download completo do catálogo/clientes a cada sincronização — apenas documentos com `updatedAt`/`version` maior que o cursor local salvo.
- Expor eventos de progresso/telemetria (quantidade sincronizada, falhas, duração) para as métricas de sincronização mencionadas na seção 14 de `tasks.md`.
- Isolar completamente por `organizationId`/`companyId`: o motor nunca sincroniza ou aplica dado de outro tenant, mesmo em caso de erro de cursor.

## Regras de negócio e restrições

- O push processa a Outbox respeitando a ordem por entidade (herdada da TASK-108); o pull nunca sobrescreve uma operação local ainda pendente na Outbox para a mesma entidade sem passar pela resolução de conflitos (TASK-110).
- Backoff exponencial não pode gerar retries infinitos sem visibilidade — ao atingir o limite, o item sai da fila ativa de retry automático e aparece como `failed` para ação manual.
- A sincronização nunca pode duplicar um pedido/atividade por reenvio de rede — idempotência é obrigatória, não opcional.
- Falha de sincronização nunca apaga dado local existente — apenas marca o status correspondente.

## Testes obrigatórios

- Teste do fluxo push: operação enviada com sucesso muda de `syncing` para `synced`.
- Teste de retry com backoff: simular falhas sucessivas e validar os intervalos/tentativas até atingir o limite e marcar `failed`.
- Teste de idempotência: reenviar a mesma operação (mesmo `clientOperationId`) não duplica o registro remoto simulado nem gera novo registro local.
- Teste do fluxo pull incremental: apenas documentos alterados após o cursor são aplicados; cursor avança corretamente após sucesso.
- Teste de isolamento multi-tenant: dado de outra organização nunca é aplicado ao banco local do usuário corrente (simular payload cruzado/malformado e confirmar rejeição).
- Teste de resiliência a queda de conexão no meio do processamento (item permanece `syncing`/`pending` recuperável, nunca corrompido).

## Critérios de aceite

- Sincronização incremental funcionando (push e pull) sem exigir carga completa a cada ciclo.
- Retry com backoff exponencial implementado e limitado.
- Idempotência comprovada por teste automatizado.
- Métricas básicas de sincronização expostas (quantidade, falhas, duração).
- `flutter analyze` e `flutter test` passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
