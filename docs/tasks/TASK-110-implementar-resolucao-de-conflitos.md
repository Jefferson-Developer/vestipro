# TASK-110 — Implementar resolução de conflitos

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-109 (motor de sincronização — a resolução de conflitos é acionada quando o pull encontra uma versão remota divergente de uma operação local pendente/aplicada)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a política de resolução de conflitos por entidade descrita na seção 5.5 de `tasks.md`: last-write-wins apenas quando seguro, merge por campo quando possível, e bloqueio com resolução manual para pedidos e dados financeiros/críticos.

## Escopo técnico

- Criar `ConflictResolutionService` com uma estratégia por tipo de entidade, configurável via um mapa `entityType → ConflictPolicy` (`LastWriteWins`, `FieldMerge`, `ManualResolution`).
- Implementar comparação de `version`/`updatedAt` entre a versão local pendente e a versão remota recebida no pull para detectar divergência real (não apenas diferença de timestamp irrelevante).
- Aplicar `LastWriteWins` somente para entidades classificadas como seguras (ex.: preferências de usuário, favoritos, rascunhos não críticos) — vencedor determinado por `updatedAt` mais recente, perdedor descartado com log/telemetria.
- Aplicar `FieldMerge` para entidades onde é possível combinar por campo (ex.: cliente com endereço alterado localmente e telefone alterado remotamente — merge preserva ambas as alterações não sobrepostas); quando o mesmo campo mudou dos dois lados, tratar como conflito não resolvível automaticamente.
- Para pedidos e dados financeiros (preço aplicado, desconto, condição de pagamento, status do pedido), nunca aplicar merge automático — marcar a entidade/registro de Outbox com status `conflict` e gerar um `ConflictRecord` persistido (tabela local) com o snapshot local e o snapshot remoto, para exibição posterior (TASK-111).
- Toda resolução (automática ou manual) grava um log de auditoria local (quem, quando, qual política, qual resultado) para rastreabilidade.

## Regras de negócio e restrições

- Pedidos, itens de pedido e qualquer entidade com implicação financeira nunca usam last-write-wins nem merge automático — sempre bloqueio + resolução manual.
- Merge por campo nunca combina dois valores do mesmo campo alterados nos dois lados sem decisão explícita — isso vira conflito, não merge silencioso.
- A perda de uma alteração local por last-write-wins deve ser sempre auditável — nunca silenciosa a ponto de não haver registro do que foi descartado.
- A política por entidade é centralizada em um único ponto (não espalhada em cada repositório), para ser auditável e testável isoladamente.

## Testes obrigatórios

- Teste de `LastWriteWins`: remoto mais recente vence, local mais recente vence, empate resolvido por regra determinística documentada.
- Teste de `FieldMerge`: alterações em campos distintos combinadas corretamente; alteração no mesmo campo dos dois lados gera conflito em vez de merge silencioso.
- Teste de `ManualResolution`: pedido com divergência gera `ConflictRecord` persistido com ambos os snapshots, status `conflict`, e nunca aplica alteração automática.
- Teste de log de auditoria: toda resolução (automática ou manual) gera entrada rastreável.
- Teste de isolamento por `entityType` garantindo que a política aplicada é sempre a esperada (nenhuma entidade financeira cai acidentalmente em `LastWriteWins`).

## Critérios de aceite

- Política de conflito documentada e implementada por tipo de entidade.
- Pedidos e dados financeiros nunca resolvidos automaticamente sem intervenção manual.
- `ConflictRecord` persistido e disponível para a tela de conflito (TASK-111).
- Toda resolução auditável.
- `flutter analyze` e `flutter test` passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
