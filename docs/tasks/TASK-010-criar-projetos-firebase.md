# TASK-010 — Criar e configurar projetos Firebase

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-002 (ambientes dev/staging/prod configurados no app — os projetos/apps Firebase precisam mapear 1:1 para esses três ambientes)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Provisionar a infraestrutura Firebase que sustentará todo o backend do VestiPro (Authentication, Firestore, Storage, Functions, Analytics, Crashlytics, Remote Config, Performance, App Check, Cloud Messaging), isolada por ambiente, e habilitar o Firebase Emulator Suite para que o time desenvolva localmente sem tocar em dados reais desde o primeiro dia.

## Escopo técnico

- Decidir e registrar via ADR (`docs/adr/000X-topologia-firebase.md`) se o VestiPro usará três projetos Firebase distintos (`vestipro-dev`, `vestipro-staging`, `vestipro-prod`) ou um único projeto com apps distintos por ambiente — a recomendação por padrão de mercado e pela necessidade de isolamento real de dados/regras é **três projetos distintos**; documentar a decisão final e o motivo.
- Instalar/usar a FlutterFire CLI (`flutterfire configure`) para gerar `firebase_options.dart` por ambiente, resultando em três arquivos (ex.: `lib/firebase_options_dev.dart`, `lib/firebase_options_staging.dart`, `lib/firebase_options_prod.dart`) ou um único arquivo com seleção condicional — manter coerência com os entrypoints criados na TASK-002.
- Registrar os apps por plataforma (Android, iOS, Web) em cada projeto/ambiente Firebase, associando `applicationId`/bundle id corretos aos flavors já configurados na TASK-002.
- Configurar o Firebase Emulator Suite (`firebase.json`, `firebase init emulators`) cobrindo ao menos Auth, Firestore, Storage e Functions, com portas documentadas e script de inicialização (`firebase emulators:start`) documentado no README.
- Garantir que os arquivos de configuração sensíveis por plataforma (`google-services.json`, `GoogleService-Info.plist`) sigam a política definida: versionados apenas para dev (se decidido) ou nunca versionados (preferível), com instrução clara no README de como obtê-los para rodar localmente.
- Nomear e organizar os apps Firebase com convenção clara (ex.: `vestipro-android-dev`, `vestipro-ios-staging`, `vestipro-web-prod`) para facilitar auditoria futura.

## Regras de negócio e restrições

- Nenhuma credencial de produção deve estar acessível/configurada na máquina de desenvolvimento padrão; o fluxo local de desenvolvimento deve apontar por padrão para o Emulator Suite ou para o projeto `dev`.
- Segredos de Firebase (chaves de API, arquivos de configuração de `prod`) nunca devem ser commitados no repositório; usar `.gitignore` e, se necessário, um cofre de segredos (ex.: variável de ambiente de CI) documentado.
- A separação de projetos deve garantir isolamento real de dados entre ambientes — nenhum dado de `dev`/`staging` pode ser gravado no projeto de `prod` por engano de configuração.

## Testes obrigatórios

- Validar que `firebase emulators:start` sobe Auth, Firestore, Storage e Functions sem erro de configuração.
- Validar que o app Flutter (`main_dev.dart`) consegue apontar para o Emulator Suite local (quando essa opção de conexão for configurada) sem erro de inicialização do Firebase — a inicialização completa do SDK é validada na TASK-011, aqui valida-se apenas que a configuração/projeto existe e é resolvível.
- Confirmar, para os três ambientes, que `flutterfire configure` gerou arquivos de opções distintos e sintaticamente válidos (compilam sem erro).

## Critérios de aceite

- Três ambientes Firebase (projetos ou apps) criados e documentados via ADR.
- `firebase_options` gerado e organizado por ambiente.
- Apps Android/iOS/Web registrados em cada ambiente Firebase, alinhados aos flavors/bundle ids da TASK-002.
- Firebase Emulator Suite configurado e documentado (Auth, Firestore, Storage, Functions no mínimo).
- Nenhuma credencial sensível de produção commitada no repositório.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
