# TASK-113 — Implementar indicador de conectividade

**Epic:** EPIC-14 — Offline e Sincronização
**Status:** ⬜ Pendente
**Depende de:** TASK-109 (motor de sincronização — o indicador reflete o estado real de conectividade e da fila que o motor consome)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar um indicador visual persistente de modo offline/online em todo o app, para que o usuário nunca fique sem saber por que uma ação parece "travada" quando, na verdade, está apenas na Outbox aguardando conexão.

## Escopo técnico

- Criar um `ConnectivityBloc`/Cubit central usando `connectivity_plus`, combinando o status de rede real com o status agregado da Outbox (há itens pending/syncing?) para produzir um estado único de exibição: online-sincronizado, online-sincronizando, offline-com-pendências, offline-sem-pendências.
- Criar componente de indicador persistente no Design System (banner discreto no topo, badge no app bar ou chip fixo — reutilizando tokens existentes), exibido de forma consistente em todas as telas relevantes (home, catálogo, pedido, CRM).
- Ao tocar/clicar no indicador, direcionar para a Central de Sincronização (TASK-112).
- Garantir que uma ação do usuário feita offline (ex.: submeter pedido) mostre feedback imediato explicando que a ação foi salva localmente e será enviada quando houver conexão — nunca dar a impressão de erro ou de ação perdida.
- Adicionar evento de Analytics (`connectivity_status_changed`) para acompanhar o tempo em modo offline.

## Regras de negócio e restrições

- O indicador nunca pode informar "sincronizado" quando existem itens pending/syncing/failed reais na Outbox — a fonte de verdade é sempre o estado agregado real, nunca apenas o status de rede do sistema operacional.
- O indicador deve ser visível sem exigir navegação — presente na estrutura de layout principal (shell de navegação), não em uma tela isolada.
- Não pode depender apenas de cor para comunicar o estado — também texto/ícone, por acessibilidade.
- Mudança de estado deve ser perceptível mas não disruptiva (sem diálogos bloqueantes a cada oscilação de rede).

## Testes obrigatórios

- Teste do Cubit cobrindo as quatro combinações de estado (online/offline × com pendência/sem pendência).
- Teste de widget do indicador em cada estado, incluindo navegação para a Central de Sincronização ao ser tocado.
- Teste garantindo que uma ação offline (ex.: submissão de pedido simulada) exibe feedback correto de "salvo localmente, será enviado".
- Teste de acessibilidade garantindo que o estado é comunicado também por texto/ícone, não só por cor.
- Golden tests do indicador em mobile, tablet e desktop, em cada estado.

## Critérios de aceite

- Indicador visível em todas as telas relevantes, refletindo o estado real (rede + Outbox).
- Usuário nunca fica sem explicação sobre por que uma ação parece pendente.
- Navegação para a Central de Sincronização funcional a partir do indicador.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
