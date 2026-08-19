# TASK-038 — Implementar wizard de configuração inicial

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-037 (criação da primeira Organization — o wizard configura a Organization já criada)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o wizard multi-step de configuração inicial da Organization (nome, segmento de moda, moeda, país, preferências), com progresso salvo localmente e retomável — o usuário pode fechar o app no meio do wizard e continuar exatamente de onde parou.

## Escopo técnico

- Criar `OnboardingWizardPage` com stepper de múltiplos passos (dados da organização, segmento — vestuário/calçados/acessórios/multimarcas, moeda e país, preferências iniciais), usando o componente de stepper do Design System.
- Criar `OnboardingCubit`/`Bloc` com estado por passo, validando os campos obrigatórios de cada passo antes de permitir avançar, e preservando os dados já preenchidos ao voltar.
- Persistir o progresso localmente (ex.: `shared_preferences` ou tabela local dedicada) para retomar o wizard exatamente no passo salvo caso o usuário feche o app antes de concluir.
- Ao concluir o último passo, chamar o caso de uso/repositório de Organization (TASK-026/TASK-037) para persistir os dados coletados.
- Exibir indicador de progresso ("Passo 2 de 4") e permitir retroceder sem perda de dados.
- Disparar evento de analytics ao concluir o wizard e, opcionalmente, ao abandonar um passo (sem bloquear a saída do usuário).

## Regras de negócio e restrições

- Moeda e país selecionados aqui condicionam formatação futura de preços e relatórios (consumido futuramente por EPIC-23/TASK-175); registrar os valores de forma normalizada (ex.: código ISO de moeda e país).
- Não permitir concluir o wizard sem os campos obrigatórios mínimos (nome da organização e segmento).
- Alterações após a conclusão do wizard são feitas na tela de Configurações da organização, fora do escopo desta task — não duplicar essa lógica aqui.

## Testes obrigatórios

- Testes de `Cubit`/`Bloc` cobrindo navegação entre passos, validação por passo, persistência do progresso e retomada a partir do passo salvo.
- Teste de widget simulando fechamento e reabertura do fluxo, verificando que o wizard retoma no passo correto com os dados preenchidos preservados.
- Teste garantindo que a conclusão é bloqueada sem os campos obrigatórios mínimos.

## Critérios de aceite

- Wizard multi-step funcional com progresso salvo localmente.
- Retomada correta do passo salvo após fechar e reabrir o app.
- Dados persistidos corretamente na Organization ao concluir o wizard.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
