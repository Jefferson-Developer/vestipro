# TASK-169 — Criar framework de integração com ERPs

**Epic:** EPIC-22 — Importação e Integrações de Dados
**Status:** ⬜ Pendente
**Depende de:** TASK-015 (Configurar Cloud Functions for Firebase — o framework de integração roda como Cloud Functions/jobs server-side).

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar uma arquitetura extensível de adapters para integração com ERPs de clientes (cada organização pode ter um ERP diferente — SAP, TOTVS, Linx etc.), com fila de sincronização bidirecional e tolerância a falhas parciais sem corromper os dados do VestiPro.

## Escopo técnico

- Definir uma interface `ErpAdapter` (server-side, Cloud Functions) com contrato único de sincronização, independente do ERP concreto (ex.: `pullInventory`, `pullPrices`, `pushOrder`, `pushCustomer`).
- Implementar um adapter de referência (ex.: via REST genérico ou importação de arquivo) para servir de exemplo e cobrir ERPs que só expõem exportação de arquivo — implementações específicas de ERPs concretos ficam fora do escopo desta task base.
- Modelar mapeamento de campos configurável por organização (ex.: campo do ERP "codigo_produto" mapeado para "sku" do VestiPro), sem exigir deploy de código para cada cliente novo.
- Implementar fila de sincronização (Cloud Tasks/Firestore + trigger) nas duas direções: saída (pedidos criados no VestiPro enviados ao ERP) e entrada (estoque e preço vindos do ERP atualizando o VestiPro).
- Implementar processamento idempotente (reprocessar o mesmo evento não duplica pedido nem corrompe estoque) e tratamento de falha parcial: item com falha em um lote não impede o processamento dos demais e fica registrado para nova tentativa/intervenção manual.
- Registrar log de sincronização por organização (histórico de execuções, sucesso/falha, payload de erro) para diagnóstico.
- Em caso de conflito entre dado local (offline-first) e dado vindo do ERP, aplicar a mesma política de resolução de conflito já definida no motor de sincronização existente.

## Regras de negócio e restrições

- Toda integração é escopada por organização — adapter, mapeamento e credenciais de uma organização nunca vazam para outra.
- Falha de sincronização de um item nunca reverte nem corrompe dados já consistentes de outros itens do mesmo lote.
- Nenhuma credencial de ERP de cliente é armazenada no código-fonte ou em configuração compartilhada entre organizações — usar armazenamento seguro por tenant, nunca em Remote Config global.
- Sincronização de entrada (estoque/preço) nunca sobrescreve um pedido em andamento no VestiPro de forma destrutiva.

## Testes obrigatórios

- Testes unitários do contrato `ErpAdapter` com adapter de referência (mock de ERP).
- Teste de idempotência: reprocessar o mesmo evento não duplica pedido nem estoque.
- Teste de falha parcial: lote com um item inválido não impede o processamento dos demais.
- Teste de isolamento multi-tenant do mapeamento de campos e das credenciais.
- Teste de resolução de conflito entre atualização local e atualização vinda do ERP.

## Critérios de aceite

- Uma organização consegue configurar mapeamento de campos sem alteração de código.
- Falha de um item nunca compromete o lote inteiro nem corrompe dados existentes.
- Log de sincronização permite diagnosticar falhas por organização.
- Arquitetura permite adicionar um novo adapter de ERP concreto sem reescrever o núcleo do framework.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
