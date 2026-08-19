# TASK-035 — Implementar cadastro inicial de usuário

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-034 (tela de login — reaproveita padrão de formulário, validação de credenciais e navegação de autenticação)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o cadastro inicial de usuário (nome, e-mail, senha) que cria a conta no Firebase Auth e inicia o fluxo de onboarding. Esta task cobre apenas a criação da conta e do perfil básico do usuário — a criação da Organization é escopo exclusivo da TASK-037.

## Escopo técnico

- Criar `SignUpPage` e `SignUpCubit`/`SignUpBloc` com campos nome, e-mail, senha e confirmação de senha, e checkbox de aceite de termos.
- Criar caso de uso `CreateAccountWithEmailAndPassword` que cria o usuário no Firebase Auth e o documento de perfil básico do usuário (nome, e-mail, `createdAt`), sem ainda vincular a nenhuma Organization.
- Validações: nome obrigatório, e-mail em formato válido, senha com política mínima de comprimento/complexidade, confirmação de senha igual à senha.
- Checkbox de aceite de termos e política de privacidade obrigatório para habilitar o botão de cadastro, com link para os textos (conteúdo definido em TASK-156/EPIC-20; aqui apenas o consumo do link e o registro do aceite).
- Registrar o aceite como consentimento com timestamp e versão do termo aceito, para rastreabilidade futura de LGPD.
- Após sucesso, redirecionar para o wizard de configuração inicial (TASK-038) quando o usuário ainda não tiver Organization vinculada.
- Disparar evento de analytics de cadastro concluído (ex.: `sign_up_completed`), sem dados pessoais sensíveis no payload.

## Regras de negócio e restrições

- Não criar Organization nesta task — essa responsabilidade pertence exclusivamente à TASK-037.
- Bloquear duplo envio do formulário; nunca limpar os campos preenchidos após um erro.
- Mapear `email-already-in-use`, senha fraca e falhas de rede do Firebase Auth para mensagens amigáveis em português.
- Botão de cadastro permanece desabilitado enquanto o aceite de termos não for marcado.

## Testes obrigatórios

- `bloc_test` cobrindo: cadastro com sucesso, e-mail já em uso, senha fraca, senhas divergentes, falha de rede, tentativa de submit sem aceitar os termos.
- Testes de widget: checkbox de termos bloqueando o envio, mensagens de erro por campo, navegação correta após sucesso.
- Teste garantindo que o consentimento de termos é registrado com timestamp e versão do termo.

## Critérios de aceite

- Cadastro cria conta no Firebase Auth e perfil básico do usuário.
- Aceite de termos obrigatório, validado e registrado como consentimento.
- Redirecionamento correto para o onboarding após sucesso.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
