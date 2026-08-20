# TASK-008 — Concluída (2026-08-20)

## Resumo

Configurada a qualidade estática base do VestiPro com `flutter_lints`, analyzer estrito para regras
críticas, gate local em PowerShell e documentação dos limites de revisão usados pelo agente Flutter
Senior.

## Agentes utilizados

- `flutter-senior-architect` (qualidade estática, regras de analyzer, gates e documentação técnica).

## Arquivos criados

- `scripts/check.ps1`
- `docs/architecture/static-quality.md`
- `docs/tasks/TASK-008-configurar-qualidade-estatica-CONCLUIDA.md`

## Arquivos alterados

- `analysis_options.yaml`
- `README.md`
- `docs/architecture/README.md`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

- Quality gate local sem dependência de Firebase, Drift, UI ou camada de negócio.
- Regras de analyzer centralizadas em `analysis_options.yaml`.
- Script de verificação mantido em `scripts/`, pronto para reaproveitamento futuro em CI/CD
  (TASK-165).

## Regras de negócio implementadas

- `print` proibido por analyzer (`avoid_print: error`).
- Chamadas em valores `dynamic` proibidas por analyzer (`avoid_dynamic_calls: error`).
- `TODO`/`FIXME` em Dart exige contexto na mesma linha (`TASK-XXX`, `VESTI-XXX`, issue `#123` ou
  URL), validado por `scripts/check.ps1`.
- Supressões globais não foram adicionadas; gerados são excluídos da análise customizada porque são
  propriedade do gerador.

## Regras Firebase implementadas

Não aplicável.

## Analytics implementado

Não aplicável.

## Crashlytics implementado

Não aplicável.

## Impacto offline

Nenhum impacto funcional. A task altera apenas qualidade estática, documentação e script local.

## Impacto multi-tenant

Nenhum impacto funcional. As regras ajudam a bloquear código morto, imports quebrados e uso indevido
de `dynamic`, reduzindo risco futuro em fluxos multi-tenant.

## Testes criados

Nenhum teste Dart permanente foi criado. A validação específica da task foi feita com um arquivo
temporário `test/static_quality_probe_test.dart`, removido após confirmar que `avoid_print` falha o
analyzer.

## Comandos executados

```powershell
.\scripts\check.ps1
flutter analyze test\static_quality_probe_test.dart
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Resultado do formatter

`dart format --set-exit-if-changed .` executado com sucesso na rodada final:
`Formatted 66 files (0 changed) in 0.45 seconds.`

## Resultado do analyzer

`flutter analyze` executado com sucesso na rodada final:
`No issues found! (ran in 3.7s)`

A prova negativa com `print` temporário falhou como esperado:
`avoid_print` reportado como erro em `test\static_quality_probe_test.dart:2:3`.

## Resultado dos testes

`flutter test` executado com sucesso: 28 testes passando, com `All tests passed!`.

## Decisões técnicas

- Mantido `package:flutter_lints/flutter.yaml` como base, com promoção explícita de diagnósticos
  críticos para erro.
- Ativados `strict-casts`, `strict-inference` e `strict-raw-types` para evitar inferência ambígua em
  código novo.
- Excluídos `*.freezed.dart`, `*.g.dart` e `*.config.dart` das customizações do analyzer, pois são
  artefatos gerados e já carregam supressões próprias.
- Criado apenas `scripts/check.ps1`, suficiente para o ambiente atual Windows/PowerShell; CI futura
  pode chamá-lo via `pwsh` ou reproduzir os comandos internos.

## Riscos conhecidos

- O check de `TODO`/`FIXME` cobre arquivos Dart em `lib/`, `test/` e `integration_test/`; docs e
  arquivos nativos não são bloqueados por esse script nesta task.
- Métricas de tamanho de arquivo, widget, método, parâmetros e aninhamento são limites de revisão,
  não falhas automáticas de build.

## Pendências

- Integrar este gate ao pipeline automatizado na TASK-165.
- Trocar ausência de logging por `AppLogger` quando a observabilidade for implementada na TASK-016.

## Evidências

- `.\scripts\check.ps1`: formatador e analyzer passaram.
- `flutter analyze test\static_quality_probe_test.dart`: falhou com `avoid_print` como esperado.
- `dart format --set-exit-if-changed .`: passou sem mudanças.
- `flutter analyze`: passou sem issues.
- `flutter test`: 28 testes passaram.

## Commit

Criado com arquivos da task adicionados explicitamente, sem `git add -A`.

Mensagem: `chore(quality): configure static quality gates`

## Push

Realizado para `origin/main`.

Resultado: `a37a585..2042ea5  main -> main`

## Hash do commit

`2042ea53987ee5b634a9e9087993dd6e317c55c1`

## Branch

`main`
