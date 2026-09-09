/**
 * Pluggable image-embedding-provider boundary for TASK-191's "reconhecimento
 * de produto por imagem" (EPIC-28) — same "single place decides which
 * concrete adapter answers, disabled-by-default, never a hardcoded secret"
 * shape already established by `llm-provider-adapter.ts` (TASK-186/187/189).
 * A separate module (not folded into `llm-provider-adapter.ts`) because the
 * capability itself is different: this boundary turns *an image* into a
 * fixed-length numeric vector ("embedding"), never free text, and every
 * concrete adapter here is judged solely by
 * {@link ImageEmbeddingProviderAdapter.embedImage}'s output shape (a
 * `number[]`), never a prompt/response pair.
 *
 * Unlike `llm-provider-adapter.ts`'s Anthropic/OpenAI adapters (plain
 * `fetch` + an API-key header), the one concrete provider implemented below
 * ({@link VertexAiMultimodalEmbeddingAdapter}) calls a Google Cloud API in
 * the *same* GCP project this Cloud Function already runs in — so it
 * authenticates with the function's own ambient service account (Application
 * Default Credentials, via `google-auth-library`, already a transitive
 * dependency of `firebase-admin` and now a direct one — see
 * `functions/package.json`) instead of a per-feature secret. Activating it in
 * production still needs an explicit decision by whoever manages this
 * project's IAM: the Cloud Functions runtime service account must be granted
 * the `roles/aiplatform.user` role (or an equivalent custom role) before any
 * call here can succeed — until then every call fails with a clear,
 * recoverable permission error, never silently.
 *
 * Endpoint/response shape reference: Vertex AI's publicly documented
 * Multimodal Embeddings API
 * (`POST https://{region}-aiplatform.googleapis.com/v1/projects/{project}/locations/{region}/publishers/google/models/multimodalembedding@001:predict`,
 * request `{"instances":[{"image":{"bytesBase64Encoded": "..."}}]}`, response
 * `{"predictions":[{"imageEmbedding": number[]}]}`). Like every other
 * concrete provider adapter in this codebase (`AnthropicLlmProviderAdapter`/
 * `OpenAiLlmProviderAdapter`), this has not been exercised against the real,
 * live API from within this sandboxed environment (no network access) — the
 * request/response contract above is this module's own documented
 * assumption, to be verified once a real GCP project enables the provider
 * (`RECOGNIZE_PRODUCT_IMAGE_PROVIDER=vertexAi`) for the first time. Recorded
 * as a known risk in TASK-191's completion notes.
 */

import { GoogleAuth } from 'google-auth-library';

export interface ImageEmbeddingRequest {
  /** Raw image bytes, base64-encoded — never a data URL/prefix. */
  base64Image: string;
  /** e.g. `image/jpeg` — passed through only for adapters that need it
   * (today none does; Vertex AI's `bytesBase64Encoded` field is
   * content-type-agnostic for the image formats this feature accepts). */
  mimeType: string;
}

export interface ImageEmbeddingProviderAdapter {
  readonly providerName: string;
  readonly model: string;
  /** Returns the fixed-length embedding vector for one image. Throws (never
   * fabricates a vector) on any provider/network/auth failure — every caller
   * treats this as a recoverable error, exactly like
   * `LlmProviderAdapter.generateText`. */
  embedImage(request: ImageEmbeddingRequest): Promise<number[]>;
}

/** Thrown by {@link DisabledImageEmbeddingProviderAdapter} and by
 * {@link VertexAiMultimodalEmbeddingAdapter} when Vertex AI itself reports a
 * fatal, non-retryable configuration problem (e.g. the runtime service
 * account lacks `aiplatform.user`) — same "distinct class for a future
 * caller to special-case" rationale as `LlmProviderNotConfiguredError`. */
export class ImageEmbeddingProviderNotConfiguredError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ImageEmbeddingProviderNotConfiguredError';
  }
}

const DEFAULT_NOT_CONFIGURED_MESSAGE =
  'Nenhum provedor de reconhecimento de imagem está configurado para este recurso.';

class DisabledImageEmbeddingProviderAdapter implements ImageEmbeddingProviderAdapter {
  readonly providerName = 'disabled';
  readonly model = 'none';

  constructor(private readonly message: string) {}

  async embedImage(): Promise<number[]> {
    throw new ImageEmbeddingProviderNotConfiguredError(this.message);
  }
}

export const DEFAULT_VERTEX_AI_MULTIMODAL_MODEL = 'multimodalembedding@001';
const VERTEX_AI_EMBEDDING_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';

/** Injectable HTTP fetcher + auth-token resolver so tests never make a real
 * network/auth call — same seam `AnthropicLlmProviderAdapter`/
 * `OpenAiLlmProviderAdapter` already give their own `fetcher`. */
export type AccessTokenResolver = () => Promise<string>;

class VertexAiMultimodalEmbeddingAdapter implements ImageEmbeddingProviderAdapter {
  readonly providerName = 'vertexAi';

  constructor(
    private readonly gcpProjectId: string,
    private readonly region: string,
    readonly model: string = DEFAULT_VERTEX_AI_MULTIMODAL_MODEL,
    private readonly fetcher: typeof fetch = fetch,
    private readonly resolveAccessToken: AccessTokenResolver = defaultAccessTokenResolver,
  ) {}

  async embedImage(request: ImageEmbeddingRequest): Promise<number[]> {
    const accessToken = await this.resolveAccessToken();
    const url =
      `https://${this.region}-aiplatform.googleapis.com/v1/projects/` +
      `${this.gcpProjectId}/locations/${this.region}/publishers/google/` +
      `models/${this.model}:predict`;

    const response = await this.fetcher(url, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        instances: [{ image: { bytesBase64Encoded: request.base64Image } }],
      }),
    });
    if (!response.ok) {
      throw new Error(`Vertex AI respondeu ${response.status} ao gerar o embedding da imagem.`);
    }
    const json = (await response.json()) as {
      predictions?: { imageEmbedding?: unknown }[];
    };
    const embedding = json.predictions?.[0]?.imageEmbedding;
    if (!Array.isArray(embedding) || embedding.length === 0) {
      throw new Error('Vertex AI retornou um embedding vazio ou inválido.');
    }
    return embedding.map((value) => Number(value));
  }
}

let cachedAuthClient: GoogleAuth | undefined;

async function defaultAccessTokenResolver(): Promise<string> {
  cachedAuthClient ??= new GoogleAuth({ scopes: [VERTEX_AI_EMBEDDING_SCOPE] });
  const client = await cachedAuthClient.getClient();
  const token = await client.getAccessToken();
  if (!token.token) {
    throw new Error('Não foi possível obter um token de acesso para o Vertex AI.');
  }
  return token.token;
}

export interface ResolveImageEmbeddingProviderAdapterParams {
  /** The feature's own `<FEATURE>_PROVIDER` value — only `'vertexAi'` is
   * implemented today; anything else (including empty/undefined) resolves to
   * the disabled adapter. */
  providerName: string | undefined;
  /** GCP project id Vertex AI calls run against — required for `'vertexAi'`,
   * ignored otherwise. */
  gcpProjectId: string | undefined;
  /** Vertex AI region (e.g. `us-central1`) — required for `'vertexAi'`,
   * ignored otherwise. */
  region: string | undefined;
  model?: string;
  /** Injectable for tests. */
  fetcher?: typeof fetch;
  resolveAccessToken?: AccessTokenResolver;
  notConfiguredMessage?: string;
}

export function resolveImageEmbeddingProviderAdapter(
  params: ResolveImageEmbeddingProviderAdapterParams,
): ImageEmbeddingProviderAdapter {
  const provider = (params.providerName ?? '').trim().toLowerCase();
  const notConfiguredMessage = params.notConfiguredMessage ?? DEFAULT_NOT_CONFIGURED_MESSAGE;
  const gcpProjectId = params.gcpProjectId?.trim();
  const region = params.region?.trim();

  if (provider !== 'vertexai' || !gcpProjectId || !region) {
    return new DisabledImageEmbeddingProviderAdapter(notConfiguredMessage);
  }
  return new VertexAiMultimodalEmbeddingAdapter(
    gcpProjectId,
    region,
    params.model?.trim() || DEFAULT_VERTEX_AI_MULTIMODAL_MODEL,
    params.fetcher,
    params.resolveAccessToken,
  );
}
