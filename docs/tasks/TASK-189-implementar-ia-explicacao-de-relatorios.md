# TASK-189 — Implementar IA generativa: explicação de relatórios

**Epic:** EPIC-28 — Inteligência Artificial Generativa
**Status:** ⬜ Pendente
**Depende de:** TASK-144 (construtor de relatórios, fonte dos dados já agregados e validados a serem narrados)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Gerar explicação em linguagem natural de um relatório/dashboard já calculado pelo construtor de relatórios (TASK-144), narrando tendências e destaques dos números existentes — a IA nunca recalcula ou reinterpreta valores, apenas descreve o que a camada de agregação já validou.

## Escopo técnico

- Cloud Function `explainReport` recebe o identificador do relatório salvo e o snapshot de dados já agregados (nunca uma query livre), montando payload com séries, totais e variação em relação ao período anterior.
- Prompt template restrito a descrever tendências, comparações e destaques presentes no payload — proibido calcular percentuais/números que não estejam no payload de entrada.
- Botão "Explicar este relatório" no construtor de relatórios e nos dashboards existentes, exibindo o texto gerado ao lado do gráfico/tabela.
- Validação pós-geração idêntica ao padrão das demais tasks de IA: todo número citado deve casar com o payload; falha de correspondência descarta a resposta.
- Cache por relatório + versão dos dados, evitando gerar novamente para o mesmo snapshot.

## Regras de negócio e restrições

- A explicação nunca é fonte de verdade dos números — o gráfico/tabela permanece a fonte, o texto apenas narra.
- Nenhum cálculo de negócio (soma, percentual, projeção) é feito pelo modelo de linguagem; todo número deve vir pronto da camada de agregação.
- Payload restrito ao escopo de acesso do usuário que solicitou (RBAC do relatório) — nunca inclui dado fora da permissão do solicitante.
- A explicação deve declarar o período de referência dos dados, evitando ambiguidade temporal.

## Testes obrigatórios

- Testes da Cloud Function: relatório com tendência de alta, de queda, dados insuficientes, payload vazio.
- Teste de rejeição de resposta com número fora do payload.
- Teste de RBAC: usuário sem permissão ao relatório não consegue gerar explicação.
- Testes de widget: exibição da explicação, erro de geração, cache reaproveitado.

## Critérios de aceite

- Toda explicação gerada é consistente com os números exibidos no relatório de origem.
- Nenhuma explicação introduz cálculo próprio divergente da camada de agregação.
- Explicação respeita o RBAC do relatório original.
- Falha de geração é tratada sem quebrar a visualização do relatório.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
