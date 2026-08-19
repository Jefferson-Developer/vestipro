# TASK-008 — Configurar qualidade estática

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-001 (projeto Flutter criado, necessário para existir um `analysis_options.yaml` alvo e código-fonte sobre o qual aplicar as regras)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Configurar as regras de qualidade estática (`flutter_lints`, `dart format`, `flutter analyze`) que serão aplicadas obrigatoriamente ao final de toda task do backlog (conforme `AGENTS.md`), para detectar cedo violações como uso de `print`, `dynamic` injustificado e código morto, antes que se acumulem em 200+ tasks.

## Escopo técnico

- Configurar `analysis_options.yaml` incluindo `package:flutter_lints/flutter.yaml` como base, com customizações adicionais alinhadas às regras do agente Flutter Senior: proibir `print` (usar `avoid_print` como erro, não apenas warning), desencorajar `dynamic` sem justificativa (`avoid_dynamic_calls` ou revisão manual documentada), proibir `TODO`/`FIXME` sem contexto (via regra customizada ou checagem em CI/script), evitar `late`/`!` desnecessários.
- Elevar de warning para erro (`analyzer: errors:` no `analysis_options.yaml`) as regras consideradas críticas para o projeto: `avoid_print`, `unnecessary_null_comparison`, `unused_import`, `unused_local_variable`, entre outras já cobertas por `flutter_lints` mas que o time decidiu tratar como bloqueantes.
- Criar um script de conveniência (ex.: `scripts/check.sh` e/ou `scripts/check.ps1`, já que o ambiente é Windows/PowerShell) que rode em sequência `dart format --set-exit-if-changed .` e `flutter analyze`, retornando código de saída não-zero se qualquer etapa falhar — para uso manual e futura integração em CI (TASK-165).
- Documentar no README (ou em `docs/architecture/`) os limites recomendados pelo agente Flutter Senior: arquivo até 300 linhas, widget principal até 150 linhas, método até 30 linhas, até 5 parâmetros por método, no máximo 3 níveis de condicionais aninhadas — deixando claro que são alertas de revisão, não falhas automáticas de build.
- Validar a configuração rodando `dart format --set-exit-if-changed .` e `flutter analyze` sobre todo o código já existente (estrutura da TASK-004 e exemplos das TASK-005/006/007), corrigindo qualquer violação encontrada.

## Regras de negócio e restrições

- Nenhuma regra de lint deve ser suprimida globalmente sem justificativa documentada; supressões pontuais (`// ignore: regra`) devem vir acompanhadas de comentário explicando o motivo.
- `print` é proibido em todo o código de produção; logging deve usar o `AppLogger` (a ser criado na TASK-016) ou, até lá, ser evitado — não usar `print` como paliativo.
- O script de verificação não deve autoformatar/autocorrigir silenciosamente em modo de checagem (`--set-exit-if-changed`), apenas reportar divergência, para não mascarar problemas em CI.

## Testes obrigatórios

- Executar `dart format --set-exit-if-changed .` sobre todo o repositório e confirmar saída limpa (sem divergências) após a configuração.
- Executar `flutter analyze` e confirmar zero erros/warnings no código existente.
- Testar deliberadamente que a regra de `print` falha o analyzer ao inserir temporariamente um `print` de teste, confirmando que a regra está ativa, e depois remover o código de teste.

## Critérios de aceite

- `analysis_options.yaml` configurado com `flutter_lints` e as regras customizadas descritas acima.
- Script de verificação (`dart format` + `flutter analyze`) criado e documentado.
- Limites de tamanho de arquivo/método documentados.
- Todo o código existente no repositório passa em `dart format --set-exit-if-changed .` e `flutter analyze` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
