# TASK-034 — Implementar tela de login

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-012 (Firebase Authentication base — precisa existir para autenticar); TASK-020 (Design System foundations — tokens de cor, tipografia e espaçamento necessários antes de construir qualquer tela)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela de login por e-mail e senha do VestiPro, ponto de entrada de todo usuário do app. A tela precisa comunicar a sofisticação de marca de moda esperada do produto, tratar todos os estados de loading/erro com clareza e ser o primeiro contato do usuário com o Design System.

## Escopo técnico

- Criar `features/authentication/presentation` com `LoginPage`, `LoginCubit`/`LoginBloc` (eventos: e-mail alterado, senha alterada, submit; estados: inicial, validando, carregando, sucesso, falha).
- Criar caso de uso `SignInWithEmailAndPassword` no domain e `AuthRepository` implementado na camada data sobre `firebase_auth`; a página nunca chama `FirebaseAuth` diretamente.
- Validar formato de e-mail e presença de senha no client antes do submit, com erro exibido próximo ao campo, sem nunca limpar os campos após erro.
- Mapear erros do Firebase Auth (`user-not-found`, `wrong-password`, `too-many-requests`, `network-request-failed`) para mensagens amigáveis em português; usar mensagem genérica ("e-mail ou senha inválidos") para não revelar se o problema é conta inexistente ou senha errada.
- Botão de submit com estado de carregamento e bloqueio de duplo envio.
- Link "Esqueci minha senha" navegando via rota tipada (`go_router`) para o fluxo da TASK-036.
- Disparar evento de analytics `login_completed` (plataforma, método `email`) após sucesso, sem registrar e-mail ou dados pessoais no evento.
- Garantir acessibilidade: labels persistentes (nunca placeholder como substituto), ordem de foco previsível, envio pela tecla "concluído" do teclado, leitor de tela e navegação por teclado no Web; toggle de visibilidade de senha.
- Layout responsivo conforme breakpoints do Design System (mobile, tablet, desktop).

## Regras de negócio e restrições

- Nenhuma chamada a `FirebaseAuth.instance` diretamente da UI — sempre via repository/usecase.
- Nunca logar ou persistir senha em texto plano.
- Mensagens de erro não podem permitir enumeração de contas existentes.
- Persistência de sessão resultante do login é responsabilidade da TASK-041; esta task não deve duplicar essa lógica.

## Testes obrigatórios

- `bloc_test` cobrindo: submit com sucesso, credencial inválida, e-mail mal formatado, falha de rede, `too-many-requests`.
- Testes de widget: estado de loading no botão, mensagem de erro exibida sem apagar os campos, navegação para recuperação de senha, toggle de senha.
- Teste de acessibilidade (semantics/labels) e teste de navegação por teclado no Web.
- Mock de `firebase_auth` via `mocktail`; nenhum teste deve depender de rede real.

## Critérios de aceite

- Login funcional via Firebase Auth em Android, iOS e Web.
- Estados loading/erro/sucesso tratados visualmente conforme o Design System.
- Evento `login_completed` registrado corretamente no `AnalyticsService`.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
