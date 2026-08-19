# TASK-037 — Implementar criação da primeira Organization

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (modelagem de Organization — define entidade/coleção que esta task passa a popular); TASK-035 (cadastro inicial de usuário — usuário autenticado que se tornará OWNER)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a operação que cria a primeira Organization de um usuário e o torna automaticamente `OWNER`, como operação transacional e idempotente executada via Cloud Function, para eliminar qualquer possibilidade de estado inconsistente (Organization sem OWNER, ou usuário vinculado parcialmente).

## Escopo técnico

- Criar Cloud Function callable `createOrganization`, autenticada, que executa em uma única transação Firestore: criação do documento `Organization`, criação do vínculo `user_organization` com role `OWNER` para o usuário autenticado, e inicialização de `Settings` padrão da organização.
- Garantir idempotência: chamadas repetidas (ex.: retry após timeout de rede) não devem criar organizações duplicadas nem múltiplos vínculos — verificar no início da Function se o usuário autenticado já possui uma Organization como criador antes de prosseguir.
- Criar `CreateOrganizationUseCase`, entidade `Organization` e `OrganizationRepository` no domain/data, chamando a Function via `cloud_functions` (nunca escrevendo diretamente na coleção `Organization` a partir do client).
- Validar no backend que o `uid` usado como criador/OWNER é sempre o do usuário autenticado da chamada (`context.auth.uid`), nunca um valor recebido do payload do client.
- Em caso de falha no meio da transação, garantir rollback completo (nenhum documento parcial persistido).
- Após sucesso, atualizar o estado local (organização ativa) para permitir a navegação para o wizard de configuração inicial (TASK-038).

## Regras de negócio e restrições

- Organization nunca pode ser criada diretamente por escrita client-side no Firestore — Security Rules devem negar escrita direta na coleção `Organization` (ver TASK-030).
- Um usuário só pode ser criador/OWNER inicial de uma Organization neste fluxo; criação de organizações adicionais por um mesmo usuário, se vier a ser suportada, é um fluxo separado e fora do escopo desta task.
- A operação deve ser auditável (gerar entrada equivalente à auditoria administrativa descrita na TASK-033, mesmo que a integração completa só seja lapidada quando aquela task existir).
- Nunca permitir estado onde a Organization exista sem nenhum usuário `OWNER` vinculado.

## Testes obrigatórios

- Testes de Cloud Function com Firebase Emulator Suite: criação bem-sucedida, chamada duplicada (idempotência), falha simulada de rede a meio da transação, chamada não autenticada (deve ser rejeitada).
- Testes de unidade do `CreateOrganizationUseCase`/`OrganizationRepository` com `mocktail`.
- Teste de Firestore Security Rules comprovando que o client não consegue escrever diretamente em `Organization` nem em `user_organization`.

## Critérios de aceite

- Organization só pode ser criada através da Cloud Function, nunca diretamente pelo client.
- Usuário criador sempre se torna `OWNER` após uma chamada bem-sucedida.
- Idempotência comprovada por teste (chamada repetida não duplica dados).
- Nenhum estado inconsistente é possível mesmo sob falha parcial simulada.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
