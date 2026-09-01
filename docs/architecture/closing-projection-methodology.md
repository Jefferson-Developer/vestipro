# Metodologia de Projeção de Fechamento

**Referência:** TASK-119, EPIC-15 — Metas e Performance Comercial.

Este documento existe para que a projeção de fechamento exibida no dashboard de atingimento
(TASK-116) nunca seja uma "caixa preta": qualquer pessoa (usuário final, suporte, auditoria) pode
consultar aqui exatamente como o número foi calculado.

## Metodologia padrão: projeção linear

```
projeção = realizado até a data / (dias decorridos do período / dias totais do período)
```

Ou seja, assume-se que o ritmo de vendas observado até o momento se mantém constante pelo restante
do período. É a extrapolação mais simples possível — escolhida deliberadamente como padrão inicial
por ser fácil de explicar e de auditar, não por ser a mais precisa.

Implementação: `LinearProjectionStrategy`
(`lib/features/targets/domain/services/projection_strategy.dart`).

### Casos-limite

- **Período ainda não iniciado, ou com menos de 10% do tempo decorrido:** a projeção ainda é
  calculada e exibida (nunca escondida), mas marcada como **baixa confiabilidade**
  (`ProjectionReliability.lowConfidence`) — pouco ritmo observado ainda para extrapolar com
  segurança.
- **Período já encerrado:** não há mais o que projetar. A "projeção" é simplesmente o valor final
  realizado (`ProjectionReliability.periodEnded`), sem aplicar a fórmula acima.
- **Meta zerada/inexistente:** percentuais de atingimento projetado nunca dividem por zero (mesma
  regra de `TargetProgressViewModel.achievementPercentage`).

## Consistência com o dashboard de atingimento (TASK-116)

`ClosingProjectionService.compute` recebe como entrada o mesmo `TargetProgressViewModel` que o
dashboard de atingimento já calculou e está exibindo — nunca busca ou recalcula o "realizado" de
forma independente. Isso garante que o valor realizado usado na projeção é sempre exatamente o
mesmo número que a tela de atingimento mostra, nunca um valor divergente.

## Extensibilidade: `ProjectionStrategy`

O cálculo de extrapolação em si fica isolado atrás da interface `ProjectionStrategy`
(`lib/features/targets/domain/services/projection_strategy.dart`), para permitir metodologias mais
sofisticadas no futuro sem quebrar o contrato de `ClosingProjectionService` nem a UI:

- **Média móvel ponderada:** dar mais peso a dias/semanas recentes do que ao início do período,
  captando mudanças de ritmo (ex.: aceleração de vendas na reta final do mês).
- **Sazonalidade:** ajustar a extrapolação por padrões históricos do período (ex.: picos de fim de
  coleção, Black Friday, datas comemorativas do varejo de moda).

Qualquer nova estratégia deve continuar expondo `methodologyDescription` — o texto curto exibido ao
usuário explicando o cálculo — para preservar a regra de nunca ser uma caixa preta.

## Regra de UI

A projeção nunca pode ser confundida visualmente com o valor realizado: é sempre rotulada como
"Projeção"/"Estimativa" e acompanhada do texto de metodologia
(`ClosingProjectionResult.methodologyDescription`). Ver `TargetDashboardPage`
(`lib/features/targets/presentation/pages/target_dashboard_page.dart`).
