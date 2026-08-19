# TASK-014 — Configurar Firebase Storage

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado — Storage é um serviço Firebase que depende da inicialização básica)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Construir a infraestrutura de upload/download de arquivos do VestiPro (fotos de produto, anexos de pedido, imagens de perfil, materiais de campanha), com isolamento correto por organização, para que features futuras (cadastro de produto com fotos, anexos de pedido, avatares de usuário) reutilizem um datasource único e seguro em vez de acessar `firebase_storage` diretamente.

## Escopo técnico

- Criar em `lib/core/services/` (ou `lib/core/network/`) um `StorageDataSource`/`StorageService` encapsulando `uploadFile`, `downloadUrl`, `deleteFile`, com suporte a progresso de upload (`UploadTask.snapshotEvents`) para feedback de UI futuro.
- Definir e implementar a convenção de path por organização alinhada à seção 20 de `tasks.md`: `organizations/{organizationId}/products/{productId}/...`, `organizations/{organizationId}/orders/{orderId}/attachments/...`, `organizations/{organizationId}/users/{userId}/avatar` — centralizando a construção desses paths em um único helper (`StoragePaths`) para evitar strings mágicas espalhadas pelo código.
- Implementar compressão/redimensionamento de imagens antes do upload usando `flutter_image_compress` (já presente no pubspec desde a TASK-003), com limites de tamanho/dimensão documentados (ex.: máximo de largura para fotos de produto) para controlar custo de armazenamento e performance de carregamento.
- Mapear erros do `firebase_storage` (`FirebaseException` com códigos como `unauthorized`, `object-not-found`, `canceled`) para a hierarquia `AppException`/`Failure` já existente.
- Suportar seleção de arquivo/imagem de origem via `image_picker` (câmera/galeria) e `file_picker` (anexos genéricos), já presentes no pubspec, encapsulados atrás da mesma abstração de serviço.
- Garantir que nenhuma UI acesse `firebase_storage` diretamente — todo upload/download passa pelo `StorageService`.

## Regras de negócio e restrições

- Todo path de Storage deve iniciar por `organizations/{organizationId}/`, nunca um path "solto" fora do escopo do tenant.
- Storage Security Rules (TASK-031) serão a fonte real de autorização; o client nunca deve assumir que "só porque o path está correto" a operação é permitida — tratar falhas de permissão como cenário esperado e recuperável.
- Uploads devem ser cancaláveis e re-tentáveis; falha de upload nunca deve travar o fluxo do usuário sem feedback claro do que falhou.
- Imagens de produto devem ser comprimidas/redimensionadas antes do upload para evitar arquivos desproporcionalmente grandes impactando performance do catálogo (EPIC-10).

## Testes obrigatórios

- Teste de integração com o Firebase Emulator Suite (Storage) cobrindo upload e download de um arquivo de teste dentro do path de uma organização.
- Teste validando que o helper `StoragePaths` gera os caminhos esperados para produto, pedido e avatar de usuário.
- Teste validando que o mapeamento de erros do Storage converte corretamente para `Failure`s de domínio.
- Teste (unitário, mockando o compressor) validando que imagens acima do limite configurado são redimensionadas/comprimidas antes do upload.

## Critérios de aceite

- `StorageService`/`StorageDataSource` implementado e testado, encapsulando upload/download/delete.
- Convenção de path por organização documentada e centralizada em um helper único.
- Compressão de imagem integrada ao fluxo de upload.
- Mapeamento de erros do Storage para `Failure`/`AppException` implementado.
- Testes de integração com Emulator Suite passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
