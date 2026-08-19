# TASK-148 — Implementar exportação PDF

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ⬜ Pendente
**Depende de:** TASK-144 (construtor de relatórios, fonte do resultado a ser exportado)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a exportação de relatórios para PDF com layout executivo profissional, aplicando o
branding da organização (logo e cores) quando configurado, para uso em apresentações e reuniões
comerciais.

## Escopo técnico

- Criar caso de uso `ExportReportToPdf`; avaliar geração client-side (pacote de PDF) vs. server-side
  via Cloud Function para relatórios pesados, seguindo os mesmos critérios de avaliação de pacotes do
  agente sênior.
- Layout com capa (nome do relatório, período, filtros aplicados), tabelas/gráficos resumidos e
  rodapé com número de página e data de geração.
- Aplicar logo e cores da organização quando configurados em `Organization` settings; usar identidade
  visual padrão do VestiPro como fallback quando a organização não configurou branding próprio.
- Reaproveitar componentes de gráfico do Design System renderizados como imagem estática no PDF (não
  interativos).
- UI: tela de pré-visualização antes de confirmar a exportação, com opção de exportar a visão atual
  ou o relatório completo.

## Regras de negócio e restrições

- Branding só é aplicado (logo/cor) quando explicitamente configurado pela organização — nunca
  inferir marca sem configuração explícita.
- Dados exibidos no PDF correspondem exatamente ao resultado já validado pela camada de agregação
  (TASK-133), sem novo cálculo feito na exportação.
- RBAC e escopo de organização/empresa ativa aplicados da mesma forma que nas demais exportações
  (TASK-146/TASK-147).
- PDFs gerados via Cloud Function seguem a mesma política de expiração e link seguro definida em
  TASK-146.

## Testes obrigatórios

- Teste de geração de PDF validando presença de capa, período e filtros aplicados.
- Teste de fallback de branding quando a organização não configurou logo/cor.
- Teste garantindo fidelidade entre os dados exibidos no PDF e o resultado da agregação (sem
  divergência).
- Teste de widget da tela de pré-visualização (loading, erro, sucesso, cancelamento).
- Teste de RBAC/escopo multi-tenant na geração do arquivo.

## Critérios de aceite

- PDF gerado tem aparência profissional, com branding da organização aplicado quando configurado.
- Números exibidos no PDF batem exatamente com o relatório exibido na tela.
- Pré-visualização permite cancelar antes de gerar o arquivo final.
- Geração de relatório grande não trava o app (delegada à Cloud Function quando necessário).

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
