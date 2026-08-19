# TASK-167 — Implementar importação de clientes via CSV/XLSX

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer — a importação precisa do modelo e das validações de cliente já definidas).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que o gestor importe uma base de clientes existente (planilha CSV/XLSX) para dentro do VestiPro, mapeando colunas da planilha para os campos do `Customer`, validando cada linha e evitando duplicidade por documento (CNPJ/CPF) ou e-mail já cadastrado na organização.

## Escopo técnico

- Tela de importação com upload de arquivo (CSV/XLSX), preview das primeiras linhas e etapa de mapeamento de colunas configurável (associar coluna da planilha a campo do `Customer`: razão social, nome fantasia, CNPJ/CPF, e-mail, telefone, endereço, segmento etc.).
- Permitir salvar um template de mapeamento reutilizável por organização, para reimportações futuras do mesmo formato de planilha.
- Processamento server-side via Cloud Function (execução em lote/paginada), com parsing incremental — nunca carregar a planilha inteira em memória de uma vez no cliente quando o arquivo for grande.
- Validação linha a linha: campos obrigatórios ausentes, CNPJ/CPF em formato inválido, e-mail malformado, duplicidade dentro do próprio arquivo e contra a base já existente da organização (comparação por documento normalizado e/ou e-mail).
- Relatório de importação: linhas processadas, importadas com sucesso, rejeitadas (com motivo por linha) e duplicadas (com opção de mesclar, ignorar ou criar mesmo assim, a critério do gestor).
- Execução assíncrona com acompanhamento de progresso (fila/job de importação com status consultável) — importação de arquivo grande não pode travar a UI nem estourar timeout de função.
- Registro de auditoria de quem importou, quando e quantos registros.

## Regras de negócio e restrições

- Duplicidade é sempre verificada por documento normalizado (CNPJ/CPF) e, secundariamente, por e-mail — nunca por nome.
- Nenhuma linha inválida pode interromper o processamento das demais; erros são coletados por linha.
- Importação nunca sobrescreve cliente existente sem decisão explícita do gestor (mesclar/ignorar/duplicar mesmo assim).
- Clientes importados entram sempre associados à organização (e empresa/filial quando aplicável) de quem executa a importação — nunca a outra organização.
- Arquivo de origem e mapeamento usados ficam registrados para eventual auditoria/replay.

## Testes obrigatórios

- Testes de parsing: CSV/XLSX válido, arquivo corrompido, colunas fora de ordem, encoding com acentuação, planilha vazia.
- Teste de detecção de duplicidade (mesmo CNPJ com/sem máscara).
- Teste de isolamento multi-tenant: importação de uma organização nunca cria/lê clientes de outra.
- Teste de widget do fluxo de mapeamento de colunas e da tela de relatório de importação (sucesso parcial, todos rejeitados, todos importados).
- Teste de carga simulando arquivo com milhares de linhas sem travar a UI.

## Critérios de aceite

- Gestor importa uma planilha real de clientes, mapeia colunas visualmente e vê relatório claro de sucesso/erro/duplicidade por linha.
- Nenhum cliente é importado para organização errada.
- Reimportação usando template salvo funciona sem remapear colunas manualmente.
- `flutter analyze`, `dart format --set-exit-if-changed .` e testes passam sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
