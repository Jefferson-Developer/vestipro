# TASK-031 — Criar Storage Security Rules

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-014 (Firebase Storage configurado), TASK-026 (Organization modelada) — as regras de Storage precisam do path por tenant e do vínculo real de membership.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar as Firebase Storage Security Rules que impedem acesso a arquivos de outra organização (fotos de produto, anexos de pedido, mídias de catálogo) e validam tipo/tamanho de arquivo no upload, complementando o isolamento multi-tenant já implementado no Firestore (TASK-030).

## Escopo técnico

- Definir/confirmar convenção de path por tenant no Storage (ex.: `organizations/{organizationId}/products/{productId}/...`, `organizations/{organizationId}/orders/{orderId}/attachments/...`), alinhada ao que a TASK-014 já deve ter estabelecido para upload seguro.
- Escrever `storage.rules` com função reutilizável equivalente à do Firestore (`isMemberOfOrganization(organizationId)`) consultando o Firestore (`organizations/{organizationId}/members/{userId}`) a partir das regras de Storage, para confirmar o vínculo real do usuário autenticado antes de liberar leitura/escrita.
- Validar no upload: tipo de arquivo permitido (ex.: apenas imagens para fotos de produto, extensões de documento permitidas para anexos) e tamanho máximo por tipo de mídia.
- Bloquear leitura/escrita de qualquer path fora da organização do usuário autenticado, mesmo que o path pareça "adivinhável".
- Garantir que arquivos de organizações diferentes nunca compartilhem o mesmo path/prefixo de forma ambígua (revisar convenção de nomenclatura para evitar colisão).

## Regras de negócio e restrições

- Nunca confiar apenas no path enviado pelo cliente como prova de pertencimento — a regra deve validar o vínculo real do usuário com a organização, assim como no Firestore.
- Upload deve ser rejeitado quando o tipo de arquivo ou tamanho excederem os limites definidos (a regra de Storage deve aplicar essa validação, não apenas a UI).
- Regras devem negar por padrão (deny by default), liberando explicitamente apenas paths e ações previstas.
- Exclusão de arquivos deve respeitar a mesma política de permissão (role/capability) usada no Firestore, quando a ação for administrativa (ex.: excluir imagem de produto de outro usuário).

## Testes obrigatórios

- Teste positivo: usuário membro de uma organização consegue ler/gravar arquivos dentro do path da própria organização.
- Teste negativo: usuário membro da Organization A não consegue ler nem gravar arquivos sob o path da Organization B.
- Teste negativo: usuário não autenticado não acessa nenhum path de Storage.
- Teste negativo: upload de arquivo com tipo não permitido (ex.: executável disfarçado de imagem) é rejeitado.
- Teste negativo: upload de arquivo acima do tamanho máximo permitido é rejeitado.
- Todos os testes executados via Firebase Emulator Suite (Storage emulator) com testes automatizados equivalentes ao `@firebase/rules-unit-testing` para Storage.

## Critérios de aceite

- `storage.rules` cobre isolamento multi-tenant completo para os paths de mídia já existentes no projeto (fotos de produto, anexos de pedido, catálogos).
- Validação de tipo e tamanho de arquivo funcionando na própria regra, não apenas na UI/client.
- Testes positivos e negativos (incluindo cross-tenant e tipo/tamanho inválidos) passam no Emulator Suite.
- Nenhum path de Storage acessível sem verificação real de membership.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
