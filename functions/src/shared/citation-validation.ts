/**
 * Shared citation/number-matching primitives for every "IA generativa"
 * feature that validates an LLM-generated text against a payload of
 * already-known numeric data points — the anti-hallucination guard first
 * built for TASK-186 ("resumo de carteira") and reused as-is by TASK-187
 * ("sugestão de abordagem comercial") instead of being copied
 * (AGENTS.md: "Não duplicar... regra"). `wallet_summary/wallet-summary-shared.ts`
 * re-exports {@link extractCitedDataPointCodes}/{@link parseFlexibleNumber}
 * from here so its own public API and tests never had to change.
 */

export const REFERENCE_BLOCK_PATTERN = /\[refs:\s*([^\]]+)\]/gi;
// Matches any digit run that may contain "." and/or "," as internal
// separators (pt-BR grouped thousands + comma-decimal, e.g. "12.500,50";
// plain comma-decimal with no thousands grouping, e.g. "12500,50"; or plain
// dot-decimal, e.g. "12500.50"), optionally preceded by "R$" and/or followed
// by "%". The captured group always starts and ends on an actual digit —
// `(?:[\d.,]*\d)?` forces the engine to backtrack off any trailing "."/","
// picked up from surrounding punctuation (e.g. a sentence-ending comma right
// before a citation block), so a token like "9800,00," from
// "...9800,00, ..." is never captured with its trailing separator glued on.
// Deliberately does not try to match ordinals/dates — those never appear in
// this vocabulary (revenue, order counts, percentages).
export const NUMBER_TOKEN_PATTERN = /(?:R\$\s*)?(\d(?:[\d.,]*\d)?)\s*%?/g;

export const NUMBER_MATCH_TOLERANCE = 0.01;

/**
 * Extracts every citation block (`[refs: a, b]`) from [text], returning the
 * distinct set of codes cited.
 */
export function extractCitedDataPointCodes(text: string): string[] {
  const codes = new Set<string>();
  for (const match of text.matchAll(REFERENCE_BLOCK_PATTERN)) {
    match[1]
      .split(',')
      .map((code) => code.trim())
      .filter((code) => code.length > 0)
      .forEach((code) => codes.add(code));
  }
  return [...codes];
}

/** Parses a pt-BR or plain-decimal numeric token into a `number`, tolerating
 * both `"1.234,56"` (thousands `.`, decimal `,`) and `"1234.56"` (plain
 * decimal `.`, no thousands separator) — the two shapes a data point's own
 * `Number.prototype.toFixed`-formatted value and a Portuguese-writing LLM are
 * each likely to produce. */
export function parseFlexibleNumber(token: string): number | null {
  const trimmed = token.trim();
  if (trimmed.length === 0) return null;
  const hasComma = trimmed.includes(',');
  const hasDot = trimmed.includes('.');
  let normalized = trimmed;
  if (hasComma && hasDot) {
    // pt-BR thousands+decimal: strip '.', decimal is ','.
    normalized = trimmed.replace(/\./g, '').replace(',', '.');
  } else if (hasComma) {
    normalized = trimmed.replace(',', '.');
  }
  const value = Number(normalized);
  return Number.isFinite(value) ? value : null;
}

/**
 * Scans [text] (with every `[refs: ...]` citation block stripped first) for
 * the first numeric token that does not match, within [tolerance], any value
 * in [knownNumericValues] — the core anti-hallucination check: returns the
 * offending token verbatim (for an error message), or `null` when every
 * number in the text is accounted for by a known value.
 */
export function findHallucinatedNumberToken(
  text: string,
  knownNumericValues: readonly number[],
  tolerance: number = NUMBER_MATCH_TOLERANCE,
): string | null {
  const textWithoutCitations = text.replace(REFERENCE_BLOCK_PATTERN, ' ');
  for (const match of textWithoutCitations.matchAll(NUMBER_TOKEN_PATTERN)) {
    const parsed = parseFlexibleNumber(match[1]);
    if (parsed == null) continue;
    const matchesKnownValue = knownNumericValues.some(
      (known) => Math.abs(known - parsed) <= tolerance,
    );
    if (!matchesKnownValue) return match[0].trim();
  }
  return null;
}
