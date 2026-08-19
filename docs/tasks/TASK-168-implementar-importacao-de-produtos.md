# TASK-168 — Implementar importação massiva de produtos

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product — importação depende do modelo de produto e variantes já definido).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir importação em lote de produtos e suas variantes (cor/tamanho/grade) via CSV/XLSX, incluindo associação de imagens por referência/SKU, com relatório detalhado de itens importados e rejeitados. É o equivalente de catálogo à TASK-167, essencial para onboarding rápido de marcas com milhares de SKUs.

## Escopo técnico

- Reutilizar (sem duplicar) a infraestrutura de mapeamento de colunas e execução assíncrona criada em TASK-167, generalizando-a para suportar múltiplos esquemas de importação (Customer, Product).
- Suportar planilha com estrutura produto+variantes (uma linha por variante ou produto com colunas de grade), com campos: SKU, referência, nome, descrição, coleção, categoria, cor, tamanho, preço base, código de barras.
- Suportar associação de imagens: upload de um pacote de imagens (zip/pasta) nomeadas por SKU/referência, casadas automaticamente durante o processamento — imagem sem SKU correspondente é reportada como não associada, sem travar a importação dos demais produtos.
- Validação linha a linha: SKU duplicado, grade de tamanho inexistente, categoria/coleção não cadastrada (com opção de criar automaticamente ou rejeitar, configurável antes de rodar a importação), preço inválido.
- Relatório de importação: produtos criados, variantes criadas, imagens associadas, imagens órfãs, linhas rejeitadas com motivo.
- Processamento em lote server-side (Cloud Function) com fila e paginação, evitando timeout em catálogos grandes (milhares de SKUs).

## Regras de negócio e restrições

- SKU/referência é único por organização; conflito é sempre reportado, nunca sobrescreve produto existente silenciosamente.
- Produto sem nenhuma imagem associada ainda é válido e entra no catálogo (fica sinalizado no relatório, não bloqueia a importação).
- Grade de tamanho referenciada precisa existir previamente na organização (ou ser criada explicitamente conforme escolha do gestor) — nunca inferida silenciosamente.
- Preço só é importado quando a planilha o fornece; esta task não cria nem gerencia políticas de tabela de preço.

## Testes obrigatórios

- Teste de parsing de planilha produto+variante (grade completa, grade parcial, SKU duplicado).
- Teste de casamento de imagem por SKU (imagem correta, imagem órfã, SKU sem imagem).
- Teste de isolamento multi-tenant do processamento e do relatório de importação.
- Teste de widget do relatório com os quatro cenários (sucesso total, parcial, todas rejeitadas, imagens órfãs).
- Teste de carga com catálogo grande simulado (milhares de linhas).

## Critérios de aceite

- Importação cria produtos e variantes corretos a partir de uma planilha real, com imagens corretamente associadas por SKU.
- Relatório indica claramente o que foi importado, rejeitado e órfão.
- Nenhuma sobrescrita silenciosa de produto existente.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
