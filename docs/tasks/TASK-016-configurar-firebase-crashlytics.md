# TASK-016 — Configurar Firebase Crashlytics

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado — Crashlytics é um serviço Firebase que depende da inicialização básica)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Configurar captura automática de crashes e erros não fatais via Firebase Crashlytics, com contexto relevante anexado (usuário, tenant, módulo, versão do app), e criar a abstração `CrashReporter` que o restante do sistema usará para reportar erros — evitando que crashes silenciosos em produção deixem o time cego sobre problemas reais dos vendedores em campo.

## Escopo técnico

- Adicionar `firebase_crashlytics` à inicialização do app, configurando `FlutterError.onError` e `PlatformDispatcher.instance.onError` para capturar automaticamente erros do framework Flutter e erros assíncronos não tratados, enviando-os ao Crashlytics.
- Criar em `lib/core/services/` (ou `lib/core/errors/`) uma abstração `CrashReporter` com métodos `recordError(exception, stackTrace, {reason, fatal})`, `setUserIdentifier(userId)`, `setCustomKey(key, value)` — desacoplando o restante do código de chamar `FirebaseCrashlytics.instance` diretamente.
- Anexar contexto seguro (nunca dados pessoais sensíveis desnecessários) a cada erro reportado: `organizationId`, `companyId` (quando aplicável), módulo/feature de origem, versão do app (via `package_info_plus`), plataforma e ambiente (dev/staging/prod).
- Configurar Crashlytics para ser desabilitado (ou apontar para um projeto de teste) no ambiente `dev`, evitando poluir os dashboards de produção com crashes de desenvolvimento — decisão a documentar.
- Integrar o `CrashReporter` com a hierarquia de exceções do `lib/core/errors/`: toda exceção classificada como `UnknownException`/`UnexpectedFailure` deve ser automaticamente reportada; exceções esperadas/tratadas (validação, permissão) não devem gerar ruído no Crashlytics.
- Adicionar um botão/comando de teste (apenas em modo debug/dev) para forçar um crash de teste e validar que ele aparece no console Firebase.

## Regras de negócio e restrições

- Nunca registrar senha, token de sessão, dados de cartão/pagamento ou qualquer dado pessoal sensível desnecessário como contexto do Crashlytics — alinhado a LGPD (seção 13 e EPIC-20 de `tasks.md`).
- Erros esperados de negócio (ex.: validação de formulário, permissão negada) não devem ser reportados como crash/erro fatal — apenas erros verdadeiramente inesperados.
- A identificação de usuário no Crashlytics deve usar um identificador técnico (ex.: `userId`), nunca e-mail ou nome em texto livre, salvo necessidade justificada e documentada.

## Testes obrigatórios

- Teste (ou verificação manual documentada, dado que Crashlytics depende de infraestrutura de plataforma) confirmando que um erro não tratado dispara `recordError` no `CrashReporter`.
- Teste unitário do `CrashReporter` validando que ele não lança exceção mesmo se o SDK subjacente falhar (defensive coding para não quebrar o app ao tentar reportar um erro).
- Verificação documentada de que um crash de teste aparece no console Firebase do ambiente correspondente.

## Critérios de aceite

- `firebase_crashlytics` integrado e capturando automaticamente erros do Flutter e assíncronos não tratados.
- `CrashReporter` implementado como abstração central, usado por todo o app (nenhuma chamada direta a `FirebaseCrashlytics.instance` fora dessa camada).
- Contexto (organização, módulo, versão, ambiente) anexado corretamente aos erros reportados, sem dados sensíveis.
- Decisão sobre comportamento em `dev` documentada.
- Testes unitários passando; crash de teste validado manualmente no console.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
