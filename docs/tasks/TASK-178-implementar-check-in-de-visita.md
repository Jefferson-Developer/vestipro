# TASK-178 — Implementar check-in de visita

**Epic:** EPIC-24 — Geolocalização e Roteirização
**Status:** ⬜ Pendente
**Depende de:** TASK-177 (roteirização de visitas), TASK-059 (atividades CRM/timeline — o check-in gera evidência vinculada à timeline do cliente).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o vendedor registre o check-in de uma visita realizada a um cliente, com geolocalização opcional mediante consentimento explícito, gerando uma evidência de visita vinculada à atividade CRM correspondente, funcionando totalmente offline com sincronização posterior.

## Escopo técnico

- Ação de "check-in" disponível a partir da rota do dia (TASK-177), da carteira ou da ficha do cliente, registrando data/hora local do dispositivo no momento da ação.
- Solicitar permissão de localização de forma explícita e opcional (o vendedor pode recusar e o check-in ainda é registrado, apenas sem coordenadas) — nunca capturar localização em segundo plano ou sem consentimento explícito no momento da ação.
- Ao conceder, capturar coordenadas do check-in e, quando fizer sentido para o produto, comparar com a coordenada cadastrada do cliente apenas como informação complementar (nunca bloquear o check-in por divergência de distância).
- Vincular automaticamente o check-in como uma atividade na timeline CRM do cliente (reaproveitando a estrutura de atividades de TASK-059), com tipo "visita", permitindo anexar observação/nota rápida no mesmo fluxo.
- Funcionar integralmente offline: check-in é salvo localmente (banco local/Outbox) imediatamente e sincronizado quando a conectividade retornar, seguindo o mesmo motor de sincronização já usado pelo restante do app.
- Marcar a parada correspondente na rota do dia como "visitada" após o check-in.

## Regras de negócio e restrições

- Consentimento de localização é sempre explícito e por ação — o vendedor entende que aquele check-in específico incluirá coordenadas.
- Ausência de permissão de localização nunca impede o check-in de ser registrado — geolocalização é evidência complementar, não requisito bloqueante.
- Check-in criado offline deve preservar timestamp local correto mesmo que a sincronização ocorra bem depois, evitando confundir com o horário de sincronização.
- Check-in gera atividade imutável na timeline do cliente (não pode ser silenciosamente apagado, apenas eventualmente marcado como cancelado/corrigido com rastro).

## Testes obrigatórios

- Teste de check-in com permissão de localização concedida e negada (ambos os fluxos válidos).
- Teste de check-in totalmente offline: criação local, persistência no Outbox, sincronização ao reconectar.
- Teste de vinculação correta do check-in como atividade na timeline CRM do cliente.
- Teste de atualização do status da parada na rota do dia após check-in.
- Teste de preservação do timestamp local mesmo com sincronização tardia.

## Critérios de aceite

- Vendedor registra check-in com ou sem geolocalização, sempre com consentimento explícito quando há captura de localização.
- Check-in funciona totalmente offline e sincroniza corretamente depois.
- Check-in aparece corretamente na timeline CRM do cliente e atualiza o progresso da rota do dia.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
