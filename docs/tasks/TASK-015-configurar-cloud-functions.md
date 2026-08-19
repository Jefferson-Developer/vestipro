# TASK-015 — Configurar Cloud Functions for Firebase

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado no client — necessário para o wrapper `cloud_functions` no lado Flutter poder ser exercitado)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Inicializar o projeto de Cloud Functions do VestiPro, que hospedará todas as regras críticas que não podem depender exclusivamente do cliente (autorização fina, cálculo de preço, geração de número de pedido, aprovações, regras financeiras), e criar o wrapper client-side padronizado para chamá-las com segurança e observabilidade.

## Escopo técnico

- Inicializar `firebase init functions` na pasta `functions/` na raiz do repositório, escolhendo TypeScript (recomendado pelo agente Flutter Senior para tipagem forte em regras críticas) com lint (`eslint`) configurado.
- Estruturar `functions/src/` por domínio, refletindo os módulos que existirão no backlog: `pricing/`, `orders/`, `insights/`, `auth/`, `admin/` (cada pasta inicialmente vazia ou com um placeholder, populada pelas tasks de domínio correspondentes ao longo do backlog — ex.: motor de precificação real na TASK-088).
- Configurar pipeline de deploy básico (`firebase deploy --only functions`) documentado por ambiente (dev/staging/prod), incluindo como apontar o deploy para o projeto Firebase correto de cada ambiente (`firebase use <alias>`).
- Criar uma Cloud Function de exemplo simples (ex.: `healthCheck` callable) para validar todo o pipeline de ponta a ponta: deploy, chamada pelo client, resposta.
- Implementar no lado Flutter (`lib/core/services/` ou `lib/core/network/`) um wrapper `CloudFunctionsService`/`FunctionsClient` em torno de `cloud_functions`, incluindo: autenticação automática do usuário atual, envio de versão do app e plataforma como metadata, geração/propagação de correlation id por chamada, retry controlado com backoff para erros transitórios, medição de tempo de resposta (preparando integração futura com Performance Monitoring na TASK-019), e tratamento padronizado de erros convertendo `FirebaseFunctionsException` para `Failure`/`AppException`.
- Configurar o Emulator Suite para Functions (`firebase emulators:start --only functions,firestore,auth`) permitindo desenvolvimento e teste local sem custo e sem tocar em ambiente real.

## Regras de negócio e restrições

- Toda regra crítica listada em `tasks.md`/`AGENTS.md` (autorização, cálculo de preço, validação de tenant, geração de número de pedido, regras financeiras, aprovações, alterações administrativas sensíveis) deve, quando implementada nas tasks futuras, residir em Cloud Functions — nunca apenas no client.
- Funções callable devem validar o vínculo real do usuário autenticado com a organização antes de qualquer operação — nunca confiar em um `organizationId` enviado no payload sem validação server-side.
- Funções devem ser idempotentes sempre que envolverem efeitos financeiros ou de estoque, para suportar retries seguros do wrapper client-side.
- Rate limiting deve ser considerado desde a estrutura inicial para funções expostas publicamente (preparação para TASK-171/API pública), mesmo que a implementação completa venha depois.

## Testes obrigatórios

- Teste (Jest ou framework equivalente configurado em `functions/`) da função `healthCheck` validando resposta esperada.
- Teste de integração client-side chamando `healthCheck` via Emulator Suite através do `CloudFunctionsService`, validando que o wrapper propaga corretamente o correlation id e trata erro simulado (timeout, função inexistente).
- Teste validando que o wrapper aplica retry apenas a erros classificados como transitórios (não retry em erros de validação/permissão).

## Critérios de aceite

- Projeto `functions/` inicializado em TypeScript, com estrutura de pastas por domínio e lint configurado.
- Pipeline de deploy documentado por ambiente.
- Função de exemplo (`healthCheck`) implementada, testada e deployável.
- `CloudFunctionsService` client-side implementado com autenticação, correlation id, retry e tratamento de erro padronizado.
- Emulator Suite de Functions configurado e testes de integração passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
