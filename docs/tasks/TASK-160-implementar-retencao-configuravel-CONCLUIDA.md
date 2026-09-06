# TASK-160 — Concluída (2026-09-05)

## Resumo

Implementada política de retenção configurável por organização e tipo de dado, com defaults seguros,
limites mínimos validados no backend e rotina diária que remove ou anonimiza dados vencidos sem tocar
registros ainda referenciados por processos ativos.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `functions/src/privacy/data-retention.ts`
- `functions/test/privacy/data-retention.test.ts`

## Arquivos alterados

- `functions/src/index.ts`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

O contrato `DataRetentionPolicy`, a validação administrativa e a aplicação da retenção ficam em Cloud
Functions. A callable grava a configuração no documento
`organizations/{organizationId}/settings/dataRetention`; a Function agendada percorre somente tenants
ativos e aplica cada regra dentro da subcoleção da própria organização.

## Regras de negócio implementadas

- Defaults sem retenção infinita: auditoria 1.825 dias, notificações lidas 90 dias, localização de
  check-in 30 dias e exportações temporárias 7 dias.
- Auditoria possui mínimo legal de 1.825 dias, imposto server-side; todos os prazos também têm limite
  máximo de 3.650 dias.
- Somente `OWNER` ou `ADMIN` com vínculo ativo pode alterar a política.
- Notificações lidas e exportações temporárias vencidas são removidas; o objeto correspondente no
  Storage também é excluído quando a exportação informa `storagePath`.
- Auditorias e check-ins vencidos são anonimizados, preservando o evento de negócio.
- `referencedByActiveProcess`, `activeReferenceCount`, `processStatus` e `activeUntil` suspendem o
  descarte enquanto houver uso ativo.

## Minimização e dados pessoais

Foi incluído junto ao contrato de retenção um inventário técnico dos campos pessoais e suas
finalidades para Auth, check-in, preferências, Analytics, auditoria, notificações e exportações. O
contrato proíbe copiar senhas/tokens, localização contínua, contatos, conteúdo de mensagem e dados
identificáveis em Analytics. Cada novo tipo tratado pela retenção precisa ter campos explicitamente
justificados pelo teste de contrato.

## Segurança e multi-tenant

O `organizationId` é usado somente para localizar o tenant depois que a Function confirma o vínculo
ativo e a função administrativa do UID autenticado. A execução agendada usa Admin SDK, ignora tenants
inativos/excluídos e nunca consulta coleções de outro tenant durante uma regra.

## Testes criados

- Expiração/anonimização por tipo e exclusão do objeto temporário no Storage por contrato injetável.
- Rejeição do prazo de auditoria abaixo do mínimo legal.
- Aplicação dos prazos seguros quando a organização não possui configuração.
- Preservação de dado vencido ligado a processo ativo.
- Cobertura do inventário de minimização para todos os tipos de retenção.
- Autorização administrativa, persistência da política e preenchimento de defaults.

## Comandos executados

- `npm run build`
- `npm run lint`
- `npx firebase emulators:exec --only firestore "npm test -- --runInBand test/privacy/data-retention.test.ts"`
- `git diff --check`

## Resultado das validações

- TypeScript build: sucesso.
- ESLint em `src` e `test`: sucesso.
- Teste no Firestore Emulator: criado, mas a execução foi bloqueada no ambiente porque `java` não
  está instalado/no `PATH` (`spawn java ENOENT`).
- `git diff --check`: apontou somente a linha em branco preexistente no `AGENTS.md`, arquivo fora do
  escopo e preservado sem alterações desta task.

## Decisões técnicas

- O descarte é idempotente: registros já anonimizados não são reprocessados.
- A política parcial é normalizada no servidor e os tipos omitidos recebem defaults seguros.
- A abstração de exclusão de Storage é injetável para teste sem depender do Storage Emulator.
- A rotina roda diariamente às 03:30 em `America/Sao_Paulo` e `southamerica-east1`.

## Riscos conhecidos

Coleções futuras que persistam dados pessoais precisam ser adicionadas ao inventário e a uma regra de
retenção antes da entrega da feature correspondente. A execução do teste de integração requer Java
para iniciar o Firestore Emulator.

## Pendências

Nenhuma pendência de implementação dentro da TASK-160. Resta somente executar o teste criado em um
ambiente com Java/Firestore Emulator disponível.

## Commit

`feat(privacy): implementa retenção e minimização de dados (TASK-160)`

## Push

Não realizado, conforme solicitado.

## Hash do commit

Preenchido após o commit local.

## Branch

`main`
