# TASK-174 — Implementar suporte a multi-idioma

**Epic:** EPIC-23 — Identidade Corporativa e Internacionalização
**Status:** ⬜ Pendente
**Depende de:** TASK-020 (Criar foundations do Design System — a internacionalização é aplicada sobre os componentes/textos já padronizados).

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implantar infraestrutura de internacionalização no app (`intl`/arquivos ARB), extrair todos os textos hardcoded restantes da interface e disponibilizar português e inglês como os dois primeiros idiomas suportados, preparando o VestiPro para expansão internacional.

## Escopo técnico

- Configurar `flutter_localizations` + `intl` com geração de código a partir de arquivos `.arb` (`app_pt.arb`, `app_en.arb`), incluindo plural/gênero quando aplicável.
- Auditar a base de código em busca de strings hardcoded remanescentes em widgets, mensagens de erro, labels de formulário, mensagens de validação e notificações — migrar todas para chaves de tradução.
- Definir estratégia de fallback (idioma não suportado cai para português, nunca exibe chave crua ao usuário, ex.: `app_title`).
- Implementar seletor de idioma nas configurações do usuário, persistido e sincronizado (Firestore + local), respeitando o funcionamento offline (idioma escolhido não pode depender de rede).
- Garantir que formatação de data, número e pluralização acompanhe o idioma selecionado via `intl`, mesmo quando a moeda/localidade de exibição (TASK-175) for diferente do idioma da interface.
- Validar que textos vindos de dados (nome de produto, cliente etc.) nunca são traduzidos — apenas a interface do aplicativo é internacionalizada.

## Regras de negócio e restrições

- Nenhum texto de interface pode ficar hardcoded após esta task — a auditoria deve cobrir todas as features existentes até o momento da execução.
- Troca de idioma nunca exige reiniciar o app nem perde estado de formulário em edição.
- Idioma é preferência do usuário, não da organização como um todo (usuários da mesma organização podem usar idiomas diferentes).
- Textos de erro vindos do backend (Cloud Functions) também devem ser traduzíveis, não apenas os textos estáticos do app.

## Testes obrigatórios

- Teste de troca de idioma em tempo de execução (pt → en) preservando estado da tela atual.
- Golden tests das telas principais em português e inglês (detectar overflow de texto mais longo).
- Teste de fallback para idioma não suportado.
- Teste de formatação de data/número/plural em cada idioma suportado.
- Lint/checagem automatizada que falha o build ao detectar string literal fora do sistema de tradução em código novo.

## Critérios de aceite

- App funciona integralmente em português e inglês, sem texto hardcoded remanescente nas telas existentes.
- Troca de idioma é imediata e não derruba estado do usuário.
- Golden tests aprovados em ambos os idiomas sem overflow de layout.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
