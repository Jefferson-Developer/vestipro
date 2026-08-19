# TASK-146 — Implementar exportação CSV

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ⬜ Pendente
**Depende de:** TASK-144 (construtor de relatórios, fonte do resultado a ser exportado)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a exportação de resultados de relatório para CSV com encoding correto para o público
brasileiro, suporte a grandes volumes sem travar a interface, e nomes de arquivo consistentes e
rastreáveis.

## Escopo técnico

- Criar caso de uso `ExportReportToCsv` operando sobre o resultado paginado retornado pela camada de
  agregação (TASK-133), nunca sobre uma cópia truncada mantida apenas no cliente.
- Processar a serialização em isolate (`compute`/`Isolate.run`) para não bloquear a UI durante a
  geração de arquivos grandes.
- Garantir encoding UTF-8 com BOM quando o export for consumido por Excel (evitar acentuação
  corrompida em pt-BR); delimitador configurável (vírgula vs. ponto-e-vírgula conforme localidade).
- Nome de arquivo determinístico: `<slug-do-relatorio>_<organizacao>_<timestamp>.csv`.
- Para volumes acima de um limite configurável, delegar a geração para uma Cloud Function que grava
  o arquivo no Storage e disponibiliza link temporário, em vez de processar no dispositivo móvel.
- Registrar evento de analytics `report_exported` com `formato=csv` e quantidade de linhas exportadas.
- Tratar erro de geração sem deixar arquivo corrompido nem travar a tela, permitindo nova tentativa.

## Regras de negócio e restrições

- Exportação client-side só é permitida até um limite de linhas configurável; acima disso, o fluxo
  assíncrono via Cloud Function é obrigatório, com notificação (TASK-151) quando o arquivo estiver
  pronto.
- Dados exportados respeitam exatamente o RBAC/escopo do usuário que solicitou — nunca vazar linha
  fora da carteira ou organização do solicitante.
- Arquivo temporário no Storage expira conforme política de ciclo de vida e é acessível apenas ao
  usuário que solicitou a exportação (regra de segurança validada por autenticação).
- Campos monetários usam separador decimal e agrupamento corretos conforme a localidade da
  organização.

## Testes obrigatórios

- Teste unitário de geração de CSV cobrindo acentuação, valores nulos e campos com vírgula/aspas
  (escaping correto).
- Teste garantindo que exportação acima do limite configurado dispara o fluxo assíncrono em vez de
  processar localmente.
- Teste de RBAC assegurando que o usuário não exporta linhas fora do próprio escopo.
- Teste de nomenclatura determinística e única do arquivo gerado.
- Teste de performance/isolate simulando grande volume sem bloquear o frame principal da UI.

## Critérios de aceite

- CSV abre corretamente no Excel em pt-BR sem caracteres corrompidos.
- Exportação de grande volume não trava a interface; indicador de progresso é exibido durante o
  processamento.
- Nome do arquivo segue padrão consistente e permite identificar relatório e data de geração.
- Exportações grandes chegam via link seguro, restrito ao usuário solicitante e com expiração.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
