# TASK-217 — Implementar gestão de mostruário, amostras e consignação

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-089 (Warehouse), TASK-090 (saldo por variante), TASK-178 (check-in de visita), TASK-199 (devoluções), TASK-200 (trocas)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Controlar mostruários, amostras e consignações usados por representantes, showrooms e clientes, separando
estoque demonstrativo de estoque vendável e criando rastreabilidade de entrega, retorno, perda, venda e
estado físico das peças.

## Escopo técnico

- Modelar `SampleKit`, `SampleItem`, `ConsignmentAgreement` e movimentações de amostra por representante,
  showroom, cliente, coleção e variante.
- Criar fluxo de saída, transferência, check-in/check-out, devolução, baixa por perda/avaria e conversão
  em venda quando a política permitir.
- Permitir evidências: fotos, observações, assinatura/aceite e vínculo com visita.
- Exibir ao vendedor quais peças estão sob sua responsabilidade e ao gestor o inventário de mostruário
  por pessoa/local/status.
- Integrar ocorrências com pós-venda, devoluções/trocas e auditoria.

## Regras de negócio e restrições

- Estoque de amostra/mostruário é separado do estoque vendável.
- Venda de amostra/consignado só ocorre com política autorizada, preço revalidado e impacto financeiro
  rastreado.
- Perda/avaria exige motivo, evidência quando configurado e aprovação conforme valor/política.
- Representante só visualiza e movimenta mostruários atribuídos a ele, salvo permissão gerencial.

## Testes obrigatórios

- Teste de movimentação de amostra entre warehouse, representante, showroom e cliente.
- Teste garantindo separação entre saldo vendável e saldo de mostruário.
- Teste de conversão autorizada em venda com revalidação de preço.
- Teste de RBAC por representante/gestor.
- Teste de evidência obrigatória para baixa por avaria/perda.

## Critérios de aceite

- Mostruário possui ciclo de vida rastreável de ponta a ponta.
- Estoque demonstrativo não contamina estoque disponível para pedido comum.
- Gestor consegue auditar responsabilidade, perdas e conversões de amostras.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes técnicos e de negócio em `.claude/agents/`
- Fluxo obrigatório: `AGENTS.md`
