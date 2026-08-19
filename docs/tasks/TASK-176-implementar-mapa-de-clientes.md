# TASK-176 — Implementar mapa de clientes

**Epic:** EPIC-24 — Geolocalização e Roteirização
**Status:** ⬜ Pendente
**Depende de:** TASK-051 (Implementar carteira de clientes — o mapa é uma visualização alternativa da mesma carteira).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Oferecer uma visualização geográfica (mapa) da carteira de clientes do vendedor, com clusterização de pins em áreas densas e os mesmos filtros já disponíveis na carteira (status, potencial, última compra), ajudando o planejamento de visitas.

## Escopo técnico

- Integrar componente de mapa (ex.: `google_maps_flutter` ou equivalente já adotado no projeto) exibindo um pin por cliente com coordenadas geográficas cadastradas/geocodificadas a partir do endereço.
- Implementar geocodificação de endereço para coordenadas (na criação/edição de cliente ou como job de backfill para clientes já cadastrados sem coordenadas), com tratamento de endereço não geocodificável (cliente aparece na lista, mas não no mapa, com aviso).
- Implementar clusterização de pins (agrupar clientes próximos quando o zoom está afastado, expandindo ao aproximar) para não poluir a tela em regiões densas.
- Reaproveitar os mesmos filtros já existentes na carteira (TASK-051): status do cliente, potencial, última compra, segmento — aplicados também ao mapa, mantendo os dois modos (lista/mapa) sincronizados nos mesmos critérios.
- Toque no pin abre um card resumido do cliente (nome, status, última compra, ação rápida de "ver detalhes"/"iniciar visita"), sem sair da tela de mapa.
- Suportar o mapa tanto em mobile (tela cheia) quanto em tablet/Web (mapa ao lado de lista, layout de duas colunas).

## Regras de negócio e restrições

- Mapa nunca exibe cliente de outra organização/carteira que não a do vendedor autenticado (mesmo isolamento já aplicado à carteira em lista).
- Cliente sem endereço geocodificável não trava a tela nem gera erro visível — apenas fica ausente do mapa com indicação clara na lista.
- Filtros aplicados no modo lista e no modo mapa devem ser exatamente os mesmos critérios, sem divergência de regra entre as duas visualizações.

## Testes obrigatórios

- Teste de geocodificação (endereço válido, endereço incompleto/inválido, timeout do serviço de geocodificação).
- Teste de clusterização com alta densidade de pins simulada.
- Teste de paridade dos filtros de carteira entre modo lista e modo mapa.
- Teste de isolamento multi-tenant/carteira (vendedor não vê clientes fora da própria carteira no mapa).
- Golden test do layout mobile (mapa cheio) e tablet/desktop (mapa + lista).

## Critérios de aceite

- Vendedor visualiza a própria carteira no mapa com pins clusterizados corretamente em áreas densas.
- Os mesmos filtros da carteira em lista funcionam identicamente no mapa.
- Nenhum vazamento de cliente fora da carteira/organização do vendedor.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
