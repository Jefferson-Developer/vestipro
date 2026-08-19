# TASK-050 — Implementar endereços e contatos do cliente

**Epic:** EPIC-06 — Clientes
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer) — endereços e contatos são vinculados à entidade Customer já definida; TASK-049 (Implementar cadastro de cliente) — esta task estende o formulário existente com as novas seções.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que cada cliente tenha múltiplos endereços (entrega, cobrança, outros) e múltiplos contatos, com um endereço e um contato principal sempre definidos, e tipos configuráveis por organização — preparando os dados que o pedido (EPIC-13) e o detalhe 360º (TASK-052) vão consumir.

## Escopo técnico

- Entidade `CustomerAddress` (tipo: entrega/cobrança/outro, logradouro, número, complemento, bairro, cidade, UF, CEP, país, `isPrimary`) e `CustomerContact` (nome, cargo, telefone, email, tipo de contato, `isPrimary`), vinculadas a `Customer`.
- Casos de uso: `AddCustomerAddress`, `UpdateCustomerAddress`, `RemoveCustomerAddress`, `SetPrimaryAddress` e equivalentes para contato (`AddCustomerContact`, `UpdateCustomerContact`, `RemoveCustomerContact`, `SetPrimaryContact`).
- Seções "Endereços" e "Contatos" no formulário de cliente (TASK-049) e, posteriormente, no detalhe 360º (TASK-052), com adição/edição/remoção inline e indicador visual do item principal.
- Tipos de endereço/contato configuráveis por organização (ex.: showroom, depósito, financeiro) além dos tipos padrão (entrega/cobrança).
- Validação de formato de CEP e preenchimento assistido de cidade/UF quando os dados já estiverem disponíveis localmente (sem dependência obrigatória de serviço externo síncrono).

## Regras de negócio e restrições

- Cliente deve sempre ter exatamente um endereço principal (quando houver ao menos um endereço) e exatamente um contato principal (quando houver ao menos um contato).
- Remover o endereço/contato principal exige promover outro a principal antes ou automaticamente — nunca deixar o cliente sem principal enquanto existirem outros itens cadastrados.
- Endereço de entrega e de cobrança podem ser o mesmo registro ou registros distintos — não duplicar dados desnecessariamente.
- Campos obrigatórios de endereço (logradouro, cidade, UF, CEP) não podem ser esvaziados pela configuração da organização.

## Testes obrigatórios

- Testes de caso de uso: adicionar endereço, definir principal, remover o principal com promoção automática do próximo item.
- Testes de widget: adicionar/editar/remover endereço e contato, exibição do indicador de item "principal".
- Teste cobrindo cliente sem nenhum endereço/contato (estado vazio) e cliente com múltiplos itens.
- Teste de validação de CEP mal formatado.

## Critérios de aceite

- Cliente suporta múltiplos endereços e contatos, com um principal sempre definido quando existir ao menos um item.
- Tipos de endereço/contato configuráveis por organização funcionam no domínio e na UI.
- `flutter analyze`, `dart format` e testes passam; estados vazio e erro tratados.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
