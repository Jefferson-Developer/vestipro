# TASK-032 — Configurar Firebase App Check

**Epic:** EPIC-03 — Segurança e Multi-Tenancy
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core integrado nas três plataformas) — App Check precisa do Firebase Core já inicializado por ambiente.

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Configurar o Firebase App Check no VestiPro para reduzir uso não autorizado dos recursos de backend (Firestore, Storage, Functions), habilitando enforcement progressivamente por ambiente — mais brando em desenvolvimento, estrito em produção — com os providers corretos por plataforma.

## Escopo técnico

- Configurar App Check para Android usando Play Integrity API (provider recomendado atual).
- Configurar App Check para iOS usando App Attest (com fallback DeviceCheck quando aplicável a versões de SO suportadas).
- Configurar App Check para Flutter Web usando reCAPTCHA Enterprise ou reCAPTCHA v3, conforme disponibilidade no projeto Firebase.
- Integrar `firebase_app_check` no bootstrap de cada entrypoint (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`), aplicando debug provider apenas em desenvolvimento.
- Configurar enforcement progressivo: modo de monitoramento/log em `development`, enforcement mais brando em `staging`, enforcement estrito (bloqueando requisições sem token válido) em `production`, para Firestore, Storage e Cloud Functions callable.
- Documentar o processo de obtenção/registro de debug tokens para desenvolvimento local e para o pipeline de CI (quando testes de integração precisarem de token de depuração).

## Regras de negócio e restrições

- Nunca habilitar enforcement estrito de App Check em ambiente de desenvolvimento local sem debug provider configurado (isso quebraria o fluxo de todos os desenvolvedores).
- Nunca desabilitar App Check em produção "temporariamente" sem registrar isso como risco documentado e prazo de reversão.
- Tokens de debug nunca devem ser commitados no repositório nem expostos em logs.
- App Check não substitui App Check/Security Rules já existentes — é uma camada adicional de proteção contra abuso, não o único mecanismo de autorização.
- A ativação deve ser testada em todas as três plataformas (Android, iOS, Web) antes de considerar a task concluída.

## Testes obrigatórios

- Teste manual/documentado de inicialização do App Check em modo debug em cada plataforma (Android, iOS, Web), confirmando que o app consegue chamar Firestore/Storage/Functions normalmente em desenvolvimento.
- Teste de que, em ambiente de staging/produção, uma requisição sem token de App Check válido é rejeitada pelo backend (validação em Cloud Function/regra que exige App Check, quando configurada).
- Teste garantindo que o debug provider não é acidentalmente habilitado no build de produção (verificação de configuração por flavor/ambiente).

## Critérios de aceite

- App Check habilitado nos três ambientes (development, staging, production) com enforcement progressivo conforme especificado.
- Providers corretos configurados por plataforma: Play Integrity (Android), App Attest (iOS), reCAPTCHA (Web).
- Nenhum segredo/token de debug commitado no repositório.
- Fluxo de desenvolvimento local não quebrado pela ativação do App Check.
- Documentação atualizada explicando como obter e configurar debug tokens.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
