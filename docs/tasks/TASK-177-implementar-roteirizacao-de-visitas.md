# TASK-177 — Implementar roteirização de visitas

**Epic:** EPIC-24 — Geolocalização e Roteirização
**Status:** ⬜ Pendente
**Depende de:** TASK-176 (Mapa de clientes — roteirização parte da seleção de clientes no mapa).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o vendedor selecione um conjunto de clientes no mapa (ou na carteira) e receba uma rota otimizada para visitá-los no dia, com integração para abrir a navegação em um app externo de mapas já instalado no dispositivo, de forma segura.

## Escopo técnico

- Tela de seleção de clientes a visitar (a partir do mapa de TASK-176 ou da carteira), com limite razoável de paradas por rota (configurável, evitando rotas absurdamente longas).
- Cálculo de rota otimizada (ordem de visita) entre os clientes selecionados a partir da localização atual do vendedor, usando serviço de roteirização/distância (ex.: Directions API do provedor de mapa já adotado no projeto).
- Exibir a rota otimizada em lista ordenada (1ª parada, 2ª parada...) e visualmente no mapa, com tempo/distância estimados entre paradas.
- Integração com apps de navegação externos (Google Maps, Waze, Apple Maps): gerar a URL/intent de navegação apenas para o destino validado (coordenadas do cliente já geocodificadas e pertencentes à carteira do vendedor) — nunca abrir uma URL arbitrária ou não validada recebida de fonte externa.
- Permitir reordenar manualmente a rota sugerida.
- Persistir a rota do dia (para retomada caso o app feche) e marcar progresso conforme os check-ins forem feitos (integra com TASK-178).

## Regras de negócio e restrições

- Rota nunca inclui cliente fora da carteira/organização do vendedor autenticado.
- Toda URL/intent aberta em app externo de navegação é construída internamente a partir de coordenadas já validadas do próprio VestiPro — nunca a partir de link recebido de terceiros ou de conteúdo não confiável.
- Otimização de rota é uma sugestão; o vendedor sempre pode reordenar ou remover paradas manualmente antes de sair.
- Falha do serviço de roteirização não pode impedir o vendedor de abrir a navegação básica para um cliente individual (degradar graciosamente para "abrir navegação para este cliente" sem otimização).

## Testes obrigatórios

- Teste de cálculo de rota com N clientes selecionados (ordem otimizada esperada com dados mock).
- Teste de reordenação manual da rota sugerida.
- Teste garantindo que a URL/intent de navegação externa só é gerada com coordenadas validadas pertencentes à carteira do vendedor.
- Teste de degradação graciosa quando o serviço de roteirização está indisponível.
- Teste de persistência/retomada da rota do dia após fechar e reabrir o app.

## Critérios de aceite

- Vendedor seleciona clientes e recebe uma rota otimizada, podendo reordenar manualmente.
- Abrir navegação externa sempre usa coordenadas validadas e pertencentes à própria carteira — nunca uma URL não validada.
- Indisponibilidade do serviço de roteirização não bloqueia a navegação básica.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
