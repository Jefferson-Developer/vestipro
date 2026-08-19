# TASK-180 — Implementar assinatura eletrônica de pedido

**Epic:** EPIC-25 — Catálogo Avançado e Portal B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-101 (Implementar submissão do pedido — a assinatura é uma etapa adicional sobre o pedido já submetido/formalizado).

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Permitir a captura de assinatura eletrônica do cliente (ou do próprio vendedor, conforme processo comercial) no momento do fechamento do pedido, anexando essa evidência de forma imutável ao pedido, com validade jurídica documentada para o processo.

## Escopo técnico

- Implementar captura de assinatura por desenho em tela (canvas de assinatura manuscrita) como mecanismo padrão, integrável no fluxo de submissão do pedido (TASK-101).
- Avaliar e documentar (decisão registrada na conclusão da task) a necessidade de integração com um provedor externo de assinatura eletrônica avançada/qualificada — implementar ao menos o ponto de extensão (interface) para plugar tal provedor no futuro, mesmo que a implementação completa do provedor externo fique fora do escopo inicial.
- Persistir a assinatura capturada (imagem/traço vetorial) como anexo imutável do pedido, com metadados: quem assinou, data/hora, dispositivo e hash do conteúdo do pedido no momento da assinatura (para comprovar que a assinatura correspondia àquele conteúdo específico).
- Bloquear alteração do pedido após assinatura sem gerar uma nova versão/aditivo explícito.
- Exibir a assinatura como parte do PDF/comprovante do pedido já gerado pelo fluxo existente.
- Funcionar offline: assinatura capturada sem conexão é armazenada localmente e sincronizada como qualquer outro dado do pedido, sem perda.

## Regras de negócio e restrições

- Uma vez assinado, o pedido (ou a versão de conteúdo vigente no momento da assinatura) é imutável; qualquer alteração posterior exige um novo processo (nova versão do pedido, nunca sobrescrita).
- O hash/checksum do conteúdo do pedido no momento da assinatura deve ser registrado para permitir comprovar posteriormente que o conteúdo não foi alterado após a assinatura.
- Assinatura capturada nunca pode ser removida ou substituída depois de anexada — apenas invalidada com rastro (ex.: pedido cancelado/nova versão), nunca apagada.
- A validade jurídica exata do modelo de assinatura por desenho em tela (vs. assinatura eletrônica qualificada) deve ser documentada explicitamente na conclusão da task, orientando o time comercial/jurídico sobre em quais contextos ela é suficiente.

## Testes obrigatórios

- Teste de captura e persistência da assinatura vinculada ao pedido, incluindo metadados (autor, data/hora, hash do conteúdo).
- Teste de bloqueio de edição de pedido já assinado.
- Teste de captura offline e sincronização posterior sem perda da assinatura.
- Teste de geração do comprovante/PDF incluindo a assinatura.
- Teste de verificação de integridade: hash do conteúdo no momento da assinatura bate com o conteúdo persistido.

## Critérios de aceite

- Pedido pode ser assinado eletronicamente (desenho em tela) e a assinatura fica anexada de forma imutável.
- Pedido assinado não pode ser alterado sem gerar nova versão explícita.
- Comprovante do pedido exibe a assinatura corretamente, inclusive quando capturada offline.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
