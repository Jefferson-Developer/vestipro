# TASK-147 — Implementar exportação XLSX

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ⬜ Pendente
**Depende de:** TASK-144 (construtor de relatórios, fonte do resultado a ser exportado)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar a exportação de resultados de relatório para planilha XLSX formatada, com cabeçalhos
fixos, tipos de dado corretos (número, data, moeda) e filtro básico aplicado na planilha gerada.

## Escopo técnico

- Criar caso de uso `ExportReportToXlsx`; avaliar previamente (conforme critérios de dependência do
  agente sênior: manutenção recente, suporte às três plataformas, necessidade real) se a geração
  ocorre client-side com pacote de planilha ou via Cloud Function server-side para volumes grandes —
  registrar a decisão como nota técnica no relatório de conclusão da task.
- Planilha com cabeçalho fixo/congelado e `AutoFilter` nativo aplicado na primeira linha.
- Formatar tipos de célula reais: data como data (não string), valores monetários como número
  formatado como moeda conforme localidade da organização, percentuais como percentual.
- Reaproveitar a mesma estratégia de volume grande delegado à Cloud Function definida em TASK-146
  (não duplicar lógica de exportação assíncrona).
- Nome de arquivo consistente com o padrão definido em TASK-146, trocando apenas a extensão para
  `.xlsx`.

## Regras de negócio e restrições

- Tipos de dado corretos por célula são obrigatórios: nunca exportar data/moeda/percentual como texto
  genérico.
- RBAC e escopo de organização idênticos aos aplicados na exportação CSV (TASK-146) — mesma origem
  de dados (camada de agregação), mesmas restrições de linha exportável.
- Nunca gerar planilha com fórmulas dinâmicas que recalculem valores sensíveis fora do controle do
  backend; os valores exportados são um retrato congelado no momento da geração.

## Testes obrigatórios

- Teste validando que datas, números e moedas são gerados com o tipo de célula correto (não como
  texto).
- Teste confirmando cabeçalho fixo e `AutoFilter` presentes na planilha gerada.
- Teste de RBAC e limite de volume equivalente ao aplicado na exportação CSV.
- Teste de geração para relatório sem linhas (planilha válida apenas com cabeçalho, sem erro).
- Teste de nomenclatura e consistência do nome do arquivo gerado.

## Critérios de aceite

- Planilha abre no Excel/Google Sheets com tipos de dado corretos e formatação legível.
- Filtro nativo funcional já aplicado na primeira linha da planilha.
- Performance e RBAC equivalentes aos da exportação CSV (TASK-146).
- Relatório sem resultados gera planilha válida (apenas cabeçalho), nunca erro ou travamento.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
