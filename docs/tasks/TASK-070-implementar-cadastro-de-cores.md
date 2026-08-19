# TASK-070 — Implementar cadastro de cores

**Epic:** EPIC-09 — Cores, Grades e Variantes
**Status:** ⬜ Pendente
**Depende de:** TASK-064 (Modelar Product) — cor é associada à entidade `Product` já modelada.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a paleta de cores reutilizável por organização (código, nome, hexadecimal/RGB, imagem principal, imagens adicionais, EANs próprios, disponibilidade), evitando que a mesma cor equivalente seja recriada repetidamente por produto.

## Escopo técnico

- Criar entidade `Color` (código, nome, hexadecimal/RGB, imagem principal, imagens adicionais, EANs próprios, disponibilidade, `organizationId`) como paleta reutilizável — nunca recriada por produto.
- Criar CRUD administrativo da paleta de cores da organização, com preview visual do swatch (hex/RGB) e upload de imagem específica da cor.
- Implementar detecção/sugestão de cor equivalente já cadastrada ao criar uma nova cor (comparação por proximidade de hex e/ou nome normalizado), alertando o usuário antes de confirmar uma possível duplicidade (ex.: "Azul Marinho" cadastrado duas vezes com grafias diferentes).
- Implementar associação de N cores a um produto (relação N:N entre `Product` e `Color` da paleta da organização).
- Validar EANs próprios de cor reutilizando o mesmo value object `Ean` criado na TASK-064.

## Regras de negócio e restrições

- A paleta de cores é única por organização; duas organizações podem ter cores com o mesmo nome sem qualquer conflito entre si.
- Criar cor com hex/nome muito próximo de uma já existente deve gerar alerta de confirmação explícita, nunca bloqueio automático nem duplicação silenciosa.
- Cor marcada como indisponível não é removida automaticamente de produtos já publicados — apenas sinalizada como indisponível.
- EAN de cor segue as mesmas regras de formato e unicidade por organização do EAN de produto.

## Testes obrigatórios

- Testes unitários do algoritmo de detecção de cor equivalente/duplicada (hex próximo, nome normalizado).
- `bloc_test` do CRUD de cor (criar, editar, marcar indisponível).
- Teste de widget do seletor de cor (swatch) e da tela de cadastro de paleta.
- Teste de integração garantindo isolamento da paleta de cores entre organizações.

## Critérios de aceite

- Paleta de cores reutilizável funcional, com alerta de possível duplicidade ao cadastrar cor semelhante.
- Associação produto-cor implementada e testada.
- EAN de cor validado com as mesmas regras de EAN de produto.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
