# TASK-064 — Modelar Product

**Epic:** EPIC-08 — Produtos e Catálogo Base
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (Modelar Organization) — Product carrega `organizationId` desde a raiz e não pode ser modelado sem o contrato de organização já definido.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Modelar a entidade de domínio `Product` com todos os atributos descritos na seção 7 de `tasks.md` (SKU, referência, nome, descrições, marca, coleção, estação, linha, categoria, subcategoria, gênero, público, tecido, composição, fornecedor, NCM, EAN, tags, status, lançamento) mais o suporte a atributos personalizados configuráveis por organização. Esta task entrega apenas domínio, DTOs, mappers e casos de uso básicos de leitura — sem UI.

## Escopo técnico

- Criar entidade `Product` (freezed, imutável, igualdade por valor) em `features/products/domain/entities` cobrindo: `sku`, `referencia`, `nome`, `descricaoCurta`, `descricaoCompleta`, `marca`, `colecaoId`, `estacaoId`, `linha`, `categoriaId`, `subcategoriaId`, `genero`, `publico`, `tecido`, `composicao`, `fornecedorId`, `ncm`, `ean`, `tags` (`List<String>`), `status`, `dataLancamento`, referências de fotos/vídeos e atributos personalizados.
- Criar `ProductDto` (json_serializable) e `ProductMapper` na camada `data`, mantendo DTO e entidade separados conforme arquitetura obrigatória.
- Modelar suporte a custom fields por organização: `ProductCustomFieldDefinition` (tipo texto/número/booleano/lista, obrigatoriedade, `organizationId`) e `ProductCustomFieldValue` vinculado ao produto.
- Adicionar os campos técnicos de sincronização obrigatórios: `id`, `organizationId`, `companyId` opcional, `createdAt`/`createdBy`, `updatedAt`/`updatedBy`, `deletedAt`, `version`, `syncStatus`.
- Criar value objects `Sku` e `Ean` com validação de formato (incluindo checksum EAN-13/EAN-8) e regra de unicidade por organização.
- Definir enums `ProductStatus` (rascunho, ativo, inativo, descontinuado), `ProductGender` e `TargetAudience` conforme vocabulário do domínio de moda.
- Implementar apenas casos de uso de leitura básica (buscar produto por id) nesta task; cadastro completo fica para TASK-065.

## Regras de negócio e restrições

- SKU e referência são únicos por organização; a unicidade final é garantida no backend, mas o value object valida formato antes de qualquer envio.
- EAN deve seguir formato válido (EAN-13/EAN-8, checksum correto) quando informado; produto pode não ter EAN próprio quando o código vive na cor/variante.
- Regra de completude para status "ativo" (nome, SKU, categoria mínimos) vive no domínio/caso de uso, nunca na entidade "burra" nem na UI.
- Atributos personalizados são específicos por organização e nunca podem vazar entre tenants.
- Nenhum `Product` deve ser instanciado sem `organizationId` associado.

## Testes obrigatórios

- Testes unitários dos value objects `Sku` e `Ean` cobrindo formatos válidos, inválidos e checksum EAN-13/EAN-8.
- Testes do `ProductMapper` (DTO ↔ entidade) cobrindo campos nulos, listas vazias e atributos personalizados ausentes.
- Testes de igualdade por valor (freezed) da entidade `Product`.
- Testes do caso de uso de busca por id cobrindo sucesso, não encontrado e tentativa de acesso a produto de outra organização (deve falhar).

## Critérios de aceite

- Entidade `Product`, DTOs e mappers compilam via `build_runner` sem erros, cobrindo todos os campos da seção 7 de `tasks.md`.
- Value objects `Sku`/`Ean` rejeitam formatos inválidos retornando `Failure` tipado, nunca exceção crua.
- Suporte a atributos personalizados por organização modelado e testado.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
