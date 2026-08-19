# TASK-179 — Implementar catálogo white-label

**Epic:** EPIC-25 — Catálogo Avançado e Portal B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-077 (grid visual de produtos), TASK-020 (foundations do Design System — o white-label é uma camada de tema sobre o catálogo e o Design System já existentes).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que uma organização personalize a identidade visual do catálogo apresentado a clientes finais (logo, cores, eventualmente domínio próprio), sem duplicar nenhum código de catálogo — toda a personalização deve ser resolvida via configuração de tema sobre o Design System já existente.

## Escopo técnico

- Modelar configuração de marca por organização (`BrandingConfig`): logo, paleta de cores primária/secundária, eventualmente domínio customizado para o catálogo/portal público.
- Estender o Design System (tokens de tema já existentes desde TASK-020) para suportar um tema derivado por organização em tempo de execução, aplicado sobre os mesmos componentes de catálogo (TASK-077) sem criar uma segunda árvore de widgets paralela.
- Aplicar o tema white-label nas superfícies voltadas ao cliente final: link de compartilhamento de catálogo (TASK-081) e, futuramente, o portal B2B (TASK-182) — sempre reaproveitando os mesmos componentes internos do vendedor.
- Validar contraste mínimo (acessibilidade) mesmo quando a organização define cores customizadas, com fallback seguro caso a cor definida não atinja contraste mínimo com o texto sobreposto.
- Tela de configuração de marca no portal admin, com pré-visualização em tempo real de como o catálogo ficará com o tema aplicado antes de publicar.

## Regras de negócio e restrições

- Nenhuma tela de catálogo pode ter versão de código duplicada por organização — toda diferença visual entre organizações deve ser resultado de configuração de tema, nunca de branch de código.
- Personalização de marca nunca pode reduzir contraste abaixo do mínimo de acessibilidade definido pelo Design System — o sistema aplica um fallback automático quando a cor customizada não atende.
- Configuração de marca pertence exclusivamente à organização que a definiu; nunca vaza para o tema padrão de outra organização.
- Alterar a configuração de marca não pode quebrar nenhuma regra de negócio do catálogo (disponibilidade, preço, permissão) — é puramente uma camada visual.

## Testes obrigatórios

- Teste de aplicação de tema customizado sobre os componentes de catálogo já existentes (sem duplicação de widget).
- Teste de fallback de contraste quando a cor customizada da organização não atende ao mínimo de acessibilidade.
- Teste de isolamento: tema de uma organização nunca aparece para outra.
- Golden tests do catálogo com tema padrão vs. tema white-label customizado.
- Teste de pré-visualização em tempo real na tela de configuração de marca.

## Critérios de aceite

- Catálogo do cliente final reflete a marca da organização (logo/cores) sem nenhuma duplicação de código de catálogo.
- Contraste mínimo de acessibilidade é sempre garantido, mesmo com tema customizado.
- Cada organização vê e aplica exclusivamente sua própria configuração de marca.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
