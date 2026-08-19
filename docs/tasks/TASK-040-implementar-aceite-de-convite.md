# TASK-040 — Implementar aceite de convite e vínculo de conta

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-039 (convite de usuários — gera o token e o documento `Invite` que esta task consome)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela de aceite de convite acessada via deep link/token, criando conta nova ou vinculando conta já existente à organização e à role definidas no convite, com tratamento claro de convite expirado, já utilizado ou revogado.

## Escopo técnico

- Criar rota tipada (ex.: `/invite/:token`) via `go_router` que captura o token recebido por deep link/URL do e-mail de convite.
- Criar `AcceptInvitePage` que valida o token junto a uma Cloud Function (`validateInvite`) antes de exibir qualquer opção ao usuário — nunca validar o token apenas no client.
- Implementar dois fluxos a partir da mesma tela: (a) usuário sem conta — reaproveita o formulário de cadastro da TASK-035, pré-preenchendo o e-mail do convite; (b) usuário já autenticado com conta compatível — apenas confirma o vínculo.
- Criar Cloud Function callable `acceptInvite`, transacional, que cria/atualiza o vínculo `user_organization` com a role definida no convite e marca o `Invite` como `accepted`.
- Tratar, com telas de erro claras e orientação de próximo passo (ex.: "solicite um novo convite"), os casos de convite expirado, já aceito ou revogado.
- Disparar evento de analytics `invite_accepted`.

## Regras de negócio e restrições

- Um convite só pode ser aceito uma única vez; uma segunda tentativa com o mesmo token deve falhar com mensagem clara, nunca aceitar novamente nem duplicar o vínculo.
- A role atribuída ao aceitar é exatamente a definida no convite; o usuário não escolhe outra role na tela de aceite.
- Definir e documentar explicitamente, na implementação, a regra sobre e-mail divergente entre o convite e a conta usada para aceitar (permitir ou bloquear — decisão registrada na evidência de conclusão).
- Toda aceitação bem-sucedida gera entrada de auditoria (ator, organização, role atribuída, timestamp).

## Testes obrigatórios

- Testes de Cloud Function com Emulator: aceite válido para conta nova, aceite válido para conta existente, convite expirado, convite já aceito (segunda tentativa), convite revogado, e-mail divergente conforme a regra documentada.
- Testes de widget: estado de erro específico para cada caso de convite inválido, fluxo completo de criação de conta a partir do convite, fluxo de vínculo de conta já autenticada.
- Teste de deep link garantindo que o token é extraído corretamente da URL/rota.

## Critérios de aceite

- Aceite de convite funcional tanto para conta nova quanto para conta existente.
- Convite expirado, já usado ou revogado tratado com mensagem clara, nunca com erro técnico cru.
- Vínculo criado com a role correta do convite, validado no backend, nunca escolhido pelo usuário.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
