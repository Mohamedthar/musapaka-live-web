export interface RetryOptions {
  retries?: number;
  retryDelay?: number;
  timeout?: number;
  onRetry?: (attempt: number, error: Error) => void;
}

export async function fetchWithRetry(
  input: RequestInfo | URL,
  init?: RequestInit,
  options: RetryOptions = {}
): Promise<Response> {
  const { retries = 3, retryDelay = 1000, timeout = 15000, onRetry } = options;

  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= retries; attempt++) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(input, {
        ...init,
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

      if (!response.ok && attempt < retries) {
        const err = new Error(`HTTP ${response.status}: ${response.statusText}`);
        onRetry?.(attempt + 1, err);
        await delay(retryDelay * (attempt + 1));
        continue;
      }

      return response;
    } catch (error) {
      clearTimeout(timeoutId);
      lastError = error instanceof Error ? error : new Error(String(error));

      if (error instanceof DOMException && error.name === 'AbortError') {
        lastError = new Error('انتهت مهلة الاتصال');
      }

      if (attempt < retries) {
        onRetry?.(attempt + 1, lastError);
        await delay(retryDelay * (attempt + 1));
      }
    }
  }

  throw lastError ?? new Error('فشل الاتصال');
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
