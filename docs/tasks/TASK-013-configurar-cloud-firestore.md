# TASK-013 — Configurar Cloud Firestore

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado — Firestore é um serviço Firebase que depende da inicialização básica)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Construir a infraestrutura de acesso ao Cloud Firestore (datasource base, conversores de tipo, tratamento de erros) que será reutilizada por praticamente todas as features de dados do VestiPro (clientes, produtos, pedidos, CRM etc.), garantindo desde já que nenhuma camada de apresentação jamais acesse o Firestore diretamente.

## Escopo técnico

- Criar em `lib/core/database/` (ou `lib/core/network/` conforme convenção definida na TASK-004) uma classe base `FirestoreDataSource<T>`/`FirestoreCollectionReference` genérica, encapsulando operações comuns: `get`, `getStream`, `query` com paginação por cursor (`startAfterDocument`), `set`, `update`, `delete` (soft delete via campo `deletedAt`, nunca exclusão física de documentos de negócio).
- Implementar conversores (`withConverter`) padronizados por entidade, delegando a serialização para os DTOs/mappers já definidos na convenção da TASK-004, garantindo tipagem forte (nunca `Map<String, dynamic>` cru vazando para fora da camada `data/`).
- Modelar o caminho inicial de collections a partir da seção 20 de `tasks.md`, com `organizations/{organizationId}` como raiz do tenant e subcollections (`customers`, `products`, `orders`, `priceLists`, `warehouses` etc.) alinhadas ao padrão de consultas reais, não por organização visual arbitrária.
- Criar uma classe/mapa central de erros do Firestore (`FirestoreExceptionMapper`) convertendo `FirebaseException` (Firestore) para a hierarquia `AppException`/`Failure` já criada (`NotFoundException`, `PermissionFailure`, `ConflictException` para falhas de transação, `ServerException` para indisponibilidade).
- Garantir suporte a paginação por cursor e streams reativos (`snapshots()`) como padrão, documentando que consultas que trariam coleções inteiras sem paginação são proibidas (alinhado à regra de nunca carregar catálogos inteiros de uma vez).
- Habilitar a persistência offline nativa do Firestore (`Settings(persistenceEnabled: true)`) como camada complementar ao banco local Drift que será construído no EPIC-14, documentando a distinção de responsabilidade entre as duas camadas de cache/offline.

## Regras de negócio e restrições

- Nenhuma UI (widget, página) pode importar `cloud_firestore` diretamente — todo acesso passa por repositório → datasource desta camada.
- Toda query deve ser escopada por `organizationId` (e `companyId` quando aplicável); nunca construir uma query "global" que dependa do chamador lembrar de filtrar por tenant.
- Nunca confiar apenas na query client-side como controle de autorização — isso é reforçado por Firestore Security Rules (TASK-030), que devem ser tratadas como a fonte real de verdade para acesso multi-tenant.
- Documentos grandes, arrays sem limite e fan-out desnecessário devem ser evitados na modelagem desde o início.

## Testes obrigatórios

- Teste de integração com o Firebase Emulator Suite validando escrita e leitura básica em uma collection de exemplo dentro de `organizations/{organizationId}`.
- Teste validando que o `FirestoreExceptionMapper` converte corretamente erros simulados (`permission-denied`, `unavailable`, `not-found`) para as `Failure`s de domínio esperadas.
- Teste validando paginação por cursor (segunda página não repete itens da primeira, preserva itens já carregados em caso de erro na página seguinte).
- Teste confirmando que a classe base de datasource não expõe `Map<String, dynamic>` cru para fora da camada `data/`.

## Critérios de aceite

- Datasource base genérico de Firestore criado em `lib/core/`, com paginação por cursor e conversores tipados.
- Mapeamento de erros do Firestore para `Failure`/`AppException` implementado e testado.
- Modelagem inicial de path documentada (`docs/architecture/firestore-schema.md` ou equivalente), alinhada à seção 20 de `tasks.md`.
- Persistência offline nativa do Firestore habilitada e sua relação com o Drift/EPIC-14 documentada.
- Testes de integração com Emulator Suite passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
