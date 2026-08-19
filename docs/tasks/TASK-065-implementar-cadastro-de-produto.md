# TASK-065 — Implementar cadastro/edição de produto

**Epic:** EPIC-08 — Produtos e Catálogo Base
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product) — fornece entidade, DTOs e value objects; TASK-020 (Criar foundations do Design System) — fornece tokens de cor, espaçamento e tipografia usados no formulário.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela administrativa de cadastro/edição de produto organizada em seções (dados básicos, categoria, conteúdo, características, SEO, agendamento), permitindo salvar rascunho incompleto e exigindo validação completa apenas no momento da publicação. Toda alteração em produto já publicado deve gerar auditoria.

## Escopo técnico

- Criar página de formulário multi-seção (stepper ou seções colapsáveis): Básico (nome, SKU, referência, marca, status), Categoria (categoria/subcategoria, coleção, estação, linha, gênero, público), Conteúdo (descrição curta/completa, tags), Características (tecido, composição, fornecedor, NCM, EAN, atributos personalizados), SEO (quando aplicável ao catálogo compartilhável) e Agendamento (data de lançamento/publicação futura).
- Criar `ProductFormBloc` dedicado, com eventos separados por seção — nunca um único bloc monolítico para o formulário inteiro.
- Persistir rascunho automaticamente (local e remoto quando possível), permitindo sair e retomar o cadastro sem perda de dados.
- Centralizar a validação de publicação em `PublishProductUseCase`, que verifica completude (nome, SKU, categoria e demais campos mínimos) antes de permitir status "ativo".
- Integrar com auditoria administrativa (TASK-033) registrando campo, valor anterior, valor novo, usuário e timestamp para cada alteração em produto já publicado.
- Layout responsivo: coluna única no mobile, duas colunas no tablet/desktop, reaproveitando componentes de formulário do Design System.

## Regras de negócio e restrições

- Rascunho pode ser salvo com campos incompletos; publicação é bloqueada até que nome, SKU, categoria e demais campos mínimos configurados estejam presentes.
- Alteração de SKU/referência após publicação deve exibir aviso explícito sobre impacto em pedidos e integrações antes de confirmar.
- Toda alteração em produto publicado gera entrada de auditoria; nenhuma edição silenciosa é permitida.
- RBAC: apenas perfis com permissão de gestão de catálogo (ex.: `ADMIN`, `SALES_MANAGER` conforme configuração) podem publicar produto; `SALES_REP` não pode criar/editar produto.
- Formulário nunca calcula regra de negócio (completude, permissão) na camada de apresentação — apenas exibe o resultado do BLoC/caso de uso.

## Testes obrigatórios

- `bloc_test` cobrindo: salvar rascunho incompleto, tentar publicar com campos faltando (bloqueado com mensagem clara), publicar com sucesso.
- Testes de widget cobrindo navegação entre seções preservando dados não salvos.
- Teste de integração com Firebase Emulator cobrindo criação, edição e geração de auditoria de produto.
- Teste de RBAC negando publicação para perfil sem permissão.

## Critérios de aceite

- Formulário completo com todas as seções descritas, rascunho funcional e publicação validada de ponta a ponta.
- Auditoria registrada para toda alteração em produto pós-publicação.
- Responsivo em mobile/tablet/desktop, com estados de loading/erro/sucesso tratados.
- `dart format`, `flutter analyze`, `flutter test` e teste de integração sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
