# TASK-186 — Implementar IA generativa: resumo de carteira do vendedor

**Epic:** EPIC-28 — Inteligência Artificial Generativa
**Status:** ⬜ Pendente
**Depende de:** TASK-052 (detalhe do cliente 360º, fonte de dados agregados por cliente), TASK-121 (engine base de insights, fonte dos insights ativos por carteira)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Gerar, sob demanda, um resumo em linguagem natural da carteira do vendedor (destaques, riscos, oportunidades), produzido a partir de dados agregados já calculados pelo backend — nunca de dados brutos não verificados nem texto livre — citando a origem de cada afirmação para permitir verificação.

## Escopo técnico

- Cloud Function `generateWalletSummary` que monta um payload estruturado (JSON) com métricas já calculadas: faturamento do período, atingimento de meta, clientes inativos, insights ativos (TASK-121) por tipo e cliente, top clientes em risco/oportunidade — nunca strings livres do vendedor.
- A Function chama o provedor de LLM configurado com um prompt template fixo que restringe a resposta a resumir os dados fornecidos, proibindo introduzir números não presentes no payload.
- Cada frase do resumo gerado referencia o dado de origem (ex.: nota expansível `[refs: insight_129_clienteX, meta_Q3]`) exibida na UI — nunca um resumo sem rastreabilidade.
- Validação pós-geração: a Function verifica se todo valor numérico citado no texto existe no payload de entrada; resposta com número fora do payload é rejeitada e regerada ou falha de forma controlada.
- Cache do resumo por vendedor/período (TTL curto) para evitar chamadas repetidas ao LLM sem mudança relevante nos dados.
- Card "Resumo da carteira" na home do vendedor, com CTA para abrir o texto completo e as referências.

## Regras de negócio e restrições

- O modelo nunca recebe dados de outra organização; o payload é montado e escopado por Cloud Function autenticada, nunca a partir de parâmetro livre do cliente.
- Nenhuma alegação numérica pode aparecer no texto final sem corresponder a um dado do payload (validação automática obrigatória, não apenas prompt engineering).
- O resumo é somente informativo — nunca aciona automaticamente uma ação comercial (desconto, contato, pedido).
- Falha de geração (indisponibilidade do provedor, resposta reprovada na validação) é tratada como estado de erro recuperável; nunca exibir texto genérico como se fosse real.
- Custo de chamadas ao LLM é controlado por cache e limite de frequência por usuário.

## Testes obrigatórios

- Testes da Cloud Function: montagem correta do payload a partir de dados mockados, rejeição de resposta com número fora do payload, timeout/erro do provedor.
- Teste de isolamento multi-tenant do payload gerado (nunca contém dado de outra organização).
- Testes de cache (reuso dentro do TTL, invalidação quando os dados mudam).
- Testes de widget: card na home com sucesso, erro, carregando, referências expansíveis.

## Critérios de aceite

- Resumo gerado nunca contém número que não exista nos dados agregados de origem (validado automaticamente).
- Toda afirmação do resumo pode ser rastreada até o dado/insight que a originou.
- Nenhum dado de outra organização chega ao prompt do modelo.
- Falha na geração é comunicada de forma clara, sem texto inventado.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
