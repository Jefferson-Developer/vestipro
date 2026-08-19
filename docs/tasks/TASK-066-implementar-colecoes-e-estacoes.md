# TASK-066 — Implementar coleções e estações

**Epic:** EPIC-08 — Produtos e Catálogo Base
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product) — coleção e estação se associam à entidade `Product` já modelada.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a organização de produtos por calendário de moda: coleções e estações, incluindo o CRUD administrativo, a associação entre produto e coleção (única ou múltipla, conforme configuração da organização) e o reaproveitamento desses dados nos filtros de catálogo.

## Escopo técnico

- Criar entidade `Collection` (nome, temporada, ano, estação associada, data de início/fim, status ativa/encerrada, `organizationId`).
- Criar entidade `Season` (verão, inverno, outono, primavera ou estações personalizadas por organização), reutilizável entre múltiplas coleções.
- Implementar associação produto-coleção suportando N:N quando a organização configurar múltiplas coleções por produto (ex.: produto contínuo presente em duas coleções), controlado por flag de configuração da organização.
- Criar tela de gestão de coleções/estações (CRUD) reaproveitando tabela administrativa e formulário do Design System.
- Reaproveitar os mesmos dados de coleção/estação no filtro de catálogo (EPIC-10), evitando duplicar taxonomia entre cadastro e vitrine.
- Criar casos de uso: criar/editar/encerrar coleção, listar produtos de uma coleção, associar/desassociar produto a coleção.

## Regras de negócio e restrições

- Coleção pertence a exatamente uma organização; não é compartilhada entre tenants.
- Quando a configuração da organização não permitir múltiplas coleções por produto, associar um novo vínculo deve remover o anterior automaticamente ou bloquear a ação — comportamento explícito, nunca silencioso.
- Encerrar uma coleção não apaga produtos: apenas marca a coleção como encerrada e reflete isso nos filtros de catálogo.
- Estação é vocabulário compartilhado da organização — não permitir duplicidade de estações equivalentes (ex.: duas entradas "Verão").

## Testes obrigatórios

- Testes unitários do caso de uso de associação produto-coleção respeitando a regra de múltiplas coleções por organização.
- `bloc_test` do CRUD de coleção (criar, editar, encerrar).
- Teste de widget da tela de gestão de coleções cobrindo estados vazio, erro e sucesso.
- Teste de integração validando que um produto associado a coleção encerrada continua consultável no cadastro, mas sinalizado como encerrado nos filtros.

## Critérios de aceite

- CRUD de coleção e estação funcional e responsivo (mobile/tablet/desktop).
- Regra de associação única/múltipla configurável por organização implementada e testada.
- Filtro de catálogo por coleção/estação funcionando com os mesmos dados usados no cadastro.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
