# TASK-012 — Configurar Firebase Authentication (base)

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado — Authentication é um serviço Firebase e depende da inicialização básica já estar funcionando)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Preparar a camada de infraestrutura de autenticação (SDK, abstrações, repositório de sessão) sem ainda construir nenhuma tela — as telas de login/cadastro são do EPIC-04 (TASK-034 em diante). O objetivo aqui é ter uma base testável e extensível de autenticação para que o restante do sistema (guards de rota, RBAC, multi-tenancy) já possa ser desenvolvido contra uma interface estável.

## Escopo técnico

- Habilitar o provedor de e-mail/senha no console Firebase (ou via configuração do Emulator Suite para dev) para os três ambientes.
- Criar em `lib/core/auth/` uma abstração `AuthService`/`AuthRepository` (contrato de domínio) com operações essenciais: `signInWithEmailAndPassword`, `signOut`, `currentUser` (stream), `sendPasswordResetEmail` — mesmo que a UI de recuperação de senha só seja implementada na TASK-036, a operação de infraestrutura já fica pronta aqui.
- Implementar a versão concreta (`data/`) usando `firebase_auth`, convertendo exceções do `FirebaseAuthException` para a hierarquia `AppException`/`Failure` já definida em `lib/core/errors/` (TASK-004) — nunca deixar `FirebaseAuthException` vazar para a camada de domínio/apresentação.
- Estruturar a abstração de forma extensível para provedores futuros (Google, Apple, SSO corporativo da TASK-173): usar um enum/estratégia de `AuthProvider` e um método genérico de login por provedor, mesmo que hoje apenas e-mail/senha esteja implementado.
- Expor um stream de estado de sessão (`authStateChanges`) consumível pelo guard de autenticação criado como stub na TASK-007, conectando-o de fato (o guard deixa de ser stub e passa a refletir sessão real).
- Registrar `AuthService`/`AuthRepository` no container de injeção de dependência (`get_it`/`injectable`) configurado na TASK-006.

## Regras de negócio e restrições

- Nenhuma tela deve ser criada nesta task — apenas infraestrutura, contratos e repositório; a UI de login pertence à TASK-034.
- Tokens de sessão nunca devem ser persistidos em `shared_preferences`; usar `flutter_secure_storage` quando persistência local de sessão for necessária (preparação para TASK-041).
- A camada de domínio deve conhecer apenas o contrato `AuthRepository`, nunca `firebase_auth` diretamente.
- Falhas de autenticação (credenciais inválidas, usuário desabilitado, rede indisponível) devem ser mapeadas para `Failure`s específicas e nunca expostas como exceção técnica crua.

## Testes obrigatórios

- Teste unitário do repositório de autenticação mapeando `FirebaseAuthException` (ex.: `user-not-found`, `wrong-password`, `network-request-failed`) para as `Failure`s de domínio corretas, usando mocks (`mocktail`) do SDK.
- Teste validando que o stream de estado de sessão emite corretamente os estados autenticado/não autenticado.
- Teste de integração com o Firebase Emulator Suite (Auth) cobrindo login com e-mail/senha válido e inválido.
- Teste confirmando que o guard de rota da TASK-007 agora reage corretamente a mudanças reais de sessão (autenticado redireciona, não autenticado bloqueia).

## Critérios de aceite

- Provedor e-mail/senha habilitado nos três ambientes/Emulator Suite.
- `AuthService`/`AuthRepository` implementado em `lib/core/auth/`, com camada `data/` isolando `firebase_auth`.
- Estrutura extensível para múltiplos provedores documentada e implementada (mesmo com um único provedor ativo hoje).
- Guard de autenticação do `go_router` conectado ao estado real de sessão.
- Testes unitários e de integração (Emulator) passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
