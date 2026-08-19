# TASK-063 — Implementar próxima melhor ação

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-062 (Implementar score do cliente e health score) — a recomendação consome o health score e os dados de recência já calculados.

> **Nota:** esta implementação pode evoluir para consumir a engine de insights (TASK-121) quando ela existir — o serviço deve ser desenhado para permitir essa substituição sem alterar o contrato de apresentação.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar uma recomendação simples baseada em regras (ex.: "cliente sem contato há X dias" → sugerir ligação) exibida como card acionável no detalhe do cliente (TASK-052) e na home do representante.

## Escopo técnico

- Serviço de domínio `NextBestActionService` com um conjunto inicial de regras simples e explicáveis: sem contato há mais de N dias → sugerir ligação; health score em faixa de risco → sugerir visita; tarefa/follow-up vencido → sugerir concluir/reagendar.
- Cada recomendação carrega: ação sugerida, motivo/evidência (dado que originou a sugestão), cliente relacionado e prioridade.
- Componente `NextBestActionCard` (Design System) exibido no detalhe do cliente e na home do representante, com CTA que leva direto à ação sugerida (ex.: abrir a tela de registrar atividade já preenchida).
- Estrutura do serviço desenhada para permitir substituição futura por consumo da engine de insights (TASK-121) sem alterar o contrato de apresentação (mesma forma de card/ação).

## Regras de negócio e restrições

- Toda recomendação deve ser explicável — nunca exibir sugestão sem mostrar o motivo/evidência ao usuário.
- Regras vivem na camada de domínio, nunca hardcoded na UI.
- Recomendações devem respeitar RBAC/carteira: vendedor só recebe próxima melhor ação para clientes da própria carteira.
- Não usar linguagem de urgência falsa ou dark patterns na apresentação da recomendação.

## Testes obrigatórios

- Teste unitário de cada regra inicial (sem contato há X dias, health score em risco, follow-up vencido) com casos limite de data.
- Teste garantindo que toda recomendação gerada carrega motivo/evidência não vazio.
- Teste de RBAC: vendedor não recebe recomendação para cliente fora da carteira.
- Teste de widget do card: exibição do motivo, CTA levando à ação correspondente.

## Critérios de aceite

- Ao menos as regras iniciais descritas funcionam e geram recomendações explicáveis.
- Card acionável aparece no detalhe do cliente e na home do representante, respeitando carteira/RBAC.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
