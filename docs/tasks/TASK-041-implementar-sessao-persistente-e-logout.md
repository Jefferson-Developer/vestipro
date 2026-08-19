# TASK-041 — Implementar sessão persistente, logout e revogação

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-012 (Firebase Authentication base — fonte do estado de autenticação); TASK-034 (tela de login — origem da sessão a ser persistida)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar persistência segura de sessão entre reinícios do app, logout que limpa dados sensíveis locais, revogação remota de sessão e tratamento transparente de expiração de token, sem nunca exigir que o usuário perceba um erro técnico de autenticação.

## Escopo técnico

- Criar `SessionService`/`AuthRepository` observando `authStateChanges()` do Firebase Auth para restaurar a sessão automaticamente ao abrir o app, sem exigir novo login enquanto o token permanecer válido.
- Persistir apenas o mínimo necessário de estado de sessão (nunca a senha, nunca o token bruto fora de storage seguro) usando `flutter_secure_storage`; refresh de token delegado ao próprio SDK do Firebase Auth.
- Implementar `logout()`: `signOut()` do Firebase Auth, limpeza de tokens e dados sensíveis locais (organização ativa em cache, dados do banco local vinculados ao usuário conforme a política de retenção definida), de forma síncrona o suficiente para impedir qualquer nova operação autenticada após o clique.
- Implementar detecção de revogação remota de sessão (ex.: usuário desativado por um admin — TASK-046): ao próximo request autenticado, forçar refresh de token e deslogar automaticamente com mensagem clara ("Sua sessão foi encerrada").
- Tratar expiração/invalidação de token em qualquer chamada autenticada, redirecionando para o login e preservando, quando possível, a rota de retorno para depois do novo login.
- Criar guard de rota (`go_router`) que verifica sessão ativa antes de liberar acesso a rotas protegidas.

## Regras de negócio e restrições

- Dados sensíveis (token, credenciais) nunca em `SharedPreferences` nem em logs — sempre em `flutter_secure_storage`.
- Revogação de sessão deve ter efeito em tempo hábil, não podendo depender apenas de o usuário reabrir o app manualmente sem qualquer verificação prévia.
- Logout deve limpar somente os dados do usuário que está saindo, sem afetar dados de outro usuário eventualmente armazenados no mesmo dispositivo, se essa configuração for suportada.

## Testes obrigatórios

- Testes de unidade do `SessionService`: restauração de sessão ao reiniciar, logout limpando o storage seguro por completo, comportamento diante de token expirado e diante de sessão revogada remotamente.
- Teste simulando perda e retomada de conectividade, garantindo que a sessão não é perdida indevidamente enquanto offline.
- Teste do guard de rota bloqueando acesso a rota protegida sem sessão válida e redirecionando corretamente.

## Critérios de aceite

- Sessão restaurada corretamente entre reinícios do app enquanto o token for válido.
- Logout limpa integralmente os dados sensíveis locais relacionados ao usuário.
- Revogação remota de sessão desloga o usuário de forma transparente, sem exigir ação manual dele para ser efetivada.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
