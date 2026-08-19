# TASK-036 — Implementar recuperação de senha

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-012 (Firebase Authentication base — necessário para `sendPasswordResetEmail`); TASK-034 (tela de login — origem do link "Esqueci minha senha")

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o fluxo de recuperação de senha via Firebase Auth, com feedback visual completo em todos os estados e sem jamais revelar se um e-mail informado corresponde a uma conta existente.

## Escopo técnico

- Criar `ForgotPasswordPage` e `ForgotPasswordCubit`/`Bloc` (estados: inicial, validando, enviando, sucesso, falha).
- Criar caso de uso `SendPasswordResetEmail` no domain, chamando `AuthRepository.sendPasswordResetEmail`, que por sua vez usa `firebase_auth`.
- Exibir, em caso de sucesso **ou** quando o Firebase retornar `user-not-found`, a mesma mensagem genérica ("Se o e-mail informado existir em nossa base, você receberá instruções para redefinir sua senha") — o mapeamento de `user-not-found` para o estado de sucesso genérico deve ocorrer na camada de apresentação/domínio, nunca na tela diretamente.
- Tratar erro de formato de e-mail inválido, `too-many-requests` (com orientação de tentar novamente mais tarde) e falha de rede com mensagens amigáveis.
- Link de retorno para a tela de login.
- Disparar evento de analytics `password_reset_requested` sem registrar o e-mail em texto claro no payload.

## Regras de negócio e restrições

- Nunca diferenciar, na resposta visual ou no tempo de resposta percebido pelo usuário, se o e-mail existe ou não na base (evitar enumeração de contas).
- Nunca expor código/mensagem técnica do Firebase Auth diretamente ao usuário final.
- Fluxo de definição da nova senha em si é conduzido pelo Firebase (link enviado por e-mail); esta task cobre a solicitação do reset, não a tela de definição de nova senha fora do app.

## Testes obrigatórios

- `bloc_test` cobrindo: sucesso, `user-not-found` (deve resultar no mesmo estado de sucesso genérico), e-mail mal formatado, `too-many-requests`, falha de rede.
- Teste de widget garantindo que a mensagem exibida é idêntica para conta existente e conta inexistente.
- Teste explícito verificando que o erro `user-not-found` do SDK nunca chega a um estado de "falha" visível ao usuário.

## Critérios de aceite

- Fluxo de reset de senha funcional via Firebase Auth.
- Mensagem de resposta nunca revela a existência ou não de uma conta.
- Erros de rede e limite de tentativas tratados com mensagens claras.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
