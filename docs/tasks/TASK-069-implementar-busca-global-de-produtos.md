# TASK-069 — Implementar busca global de produtos

**Epic:** EPIC-08 — Produtos e Catálogo Base
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product) — fornece a entidade e os campos (nome, SKU, referência, EAN, tags) que a busca indexa.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a busca global de produtos por nome, SKU, referência, EAN e tags, funcionando tanto online (Firestore) quanto offline (índice local já sincronizado no dispositivo), com debounce e cancelamento de buscas anteriores.

## Escopo técnico

- Criar `SearchProductsUseCase` buscando por nome, SKU, referência, EAN e tags, com normalização de texto (case e acentuação) para melhorar o recall.
- Implementar busca online via Firestore (campo normalizado para busca e/ou índice composto, já que Firestore não tem full-text nativo) e busca offline via índice local (Drift) usando os dados já sincronizados no dispositivo.
- Criar BLoC de busca com debounce (300–400ms) e cancelamento explícito de buscas anteriores (transformer `restartable`), evitando resultados fora de ordem.
- Integrar com o componente de busca reutilizável do Design System (TASK-021/024), disponível a partir do catálogo, do pedido e das telas administrativas.
- Sinalizar na UI quando o resultado vem de dado offline potencialmente desatualizado vs. resultado remoto atualizado.

## Regras de negócio e restrições

- Busca nunca pode retornar produtos de outra organização — toda query (local e remota) é escopada por `organizationId`.
- Resultado offline pode estar desatualizado; a UI deve comunicar isso quando relevante, nunca apresentar como certeza absoluta.
- Busca por EAN deve considerar tanto o EAN do produto quanto os EANs próprios de cor/variante quando essas entidades já existirem (TASK-070/072).

## Testes obrigatórios

- `bloc_test` cobrindo debounce, cancelamento de busca anterior e resultado vazio.
- Testes unitários de normalização de texto (acentos, maiúsculas/minúsculas) na busca.
- Teste de integração comparando busca offline (Drift) e online (Firestore/Emulator) para o mesmo termo.
- Teste garantindo isolamento multi-tenant nos dois modos de busca.

## Critérios de aceite

- Busca funcional online e offline, cobrindo nome, SKU, referência, EAN e tags.
- Debounce e cancelamento de buscas anteriores implementados e testados.
- Isolamento multi-tenant garantido em ambos os modos de busca.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
