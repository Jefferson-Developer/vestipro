# TASK-164 — Otimizar performance

**Epic:** EPIC-21 — Qualidade, Performance e Release (fim do MVP)
**Status:** ⬜ Pendente
**Depende de:** TASK-095 (Order/OrderItem, fluxo de submissão a otimizar), TASK-104 (histórico e
duplicação de pedido, tela sensível a otimizar), TASK-077 (grid visual de produtos, tela sensível a
otimizar)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Reduzir jank, número de leituras Firestore e uso de memória nas telas mais sensíveis do app, medindo
e documentando métricas antes/depois com o Performance Monitoring já configurado (TASK-019), como
quarto pilar do checklist de qualidade que antecede o release do MVP (TASK-166).

## Escopo técnico

- Medir o baseline atual usando Firebase Performance Monitoring (TASK-019) e profiling local
  (DevTools) nas telas priorizadas: grid visual de produtos (TASK-077), listagem/histórico de pedidos
  (TASK-104) e fluxo de criação/submissão de pedido (TASK-095).
- Reduzir jank: revisar rebuilds amplos (aplicar `BlocSelector`/`const` onde faltar), listas grandes
  com builders/slivers, imagens redimensionadas e cacheadas (`cached_network_image` com tamanho
  alvo).
- Reduzir número de leituras Firestore: revisar queries client-side que buscam mais dados que o
  necessário, paginação por cursor ausente, ou dependência de agregação client-side que deveria vir
  da camada de agregação (TASK-133).
- Reduzir uso de memória: identificar vazamentos (listeners/streams não cancelados), imagens em
  resolução acima do necessário, caches sem limite definido.
- Documentar métricas antes/depois (frame time, tempo de carregamento, leituras Firestore por tela,
  uso de memória) como evidência objetiva da otimização.

## Regras de negócio e restrições

- Otimização não pode alterar comportamento funcional/regra de negócio das telas otimizadas — a
  mudança é de performance, não de escopo.
- Nenhuma otimização pode enfraquecer isolamento multi-tenant, RBAC ou comportamento offline
  existente.
- Medir sempre antes de otimizar; não aplicar mudança "especulativa" sem dado de profiling que a
  justifique.

## Testes obrigatórios

- Medição (script de profiling documentado) comparando frame time/jank antes e depois nas telas
  otimizadas.
- Teste/medição garantindo que a contagem de leituras Firestore por operação caiu (ou justificativa
  documentada quando não foi possível reduzir).
- Testes de regressão (widget/bloc) garantindo que as otimizações não quebraram nenhum comportamento
  existente das telas tocadas.
- Verificação de memória (profile mode) validando ausência de vazamento óbvio nos fluxos otimizados.
- Revalidação de que offline e RBAC continuam funcionando normalmente após as mudanças.

## Critérios de aceite

- Métricas de performance (frame time, leituras Firestore, memória) documentadas antes/depois
  mostrando melhoria mensurável nas telas priorizadas.
- Nenhuma regressão funcional identificada nos testes existentes das telas otimizadas.
- Firebase Performance Monitoring reflete a melhoria nos traces configurados em TASK-019.
- Isolamento multi-tenant, RBAC e comportamento offline preservados.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
