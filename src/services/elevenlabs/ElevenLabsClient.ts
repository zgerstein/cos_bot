import { ElevenLabsConfig, ElevenLabsResponse, ElevenLabsError, TranscriptionJob, TranscriptionResult } from '../../types';
import { ELEVENLABS_CONFIG } from '../../config';

const MAX_RETRIES = 3;
const INITIAL_RETRY_DELAY = 1000; // 1 second

export class ElevenLabsClientError extends Error {
  constructor(
    message: string,
    public status?: number,
    public statusText?: string,
    public originalError?: unknown
  ) {
    super(message);
    this.name = 'ElevenLabsClientError';
  }
}

export class ElevenLabsClient {
  private config: ElevenLabsConfig;

  constructor(config: Partial<ElevenLabsConfig> = {}) {
    this.config = {
      ...ELEVENLABS_CONFIG,
      ...config,
    };

    this.validateConfig();
  }

  private validateConfig(): void {
    if (!this.config.apiKey) {
      throw new ElevenLabsClientError('ElevenLabs API key is required');
    }
    if (!this.config.apiKey.startsWith('sk-')) {
      throw new ElevenLabsClientError('Invalid ElevenLabs API key format. Key should start with "sk-"');
    }
  }

  private getHeaders(): HeadersInit {
    try {
      return {
        'xi-api-key': this.config.apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    } catch (error) {
      throw new ElevenLabsClientError(
        'Failed to generate headers',
        undefined,
        undefined,
        error
      );
    }
  }

  private async sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private async retryWithBackoff<T>(
    operation: () => Promise<T>,
    retryCount: number = 0
  ): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      // Don't retry for client errors (4xx)
      if (error instanceof ElevenLabsClientError && error.status && error.status >= 400 && error.status < 500) {
        throw error;
      }

      if (retryCount >= MAX_RETRIES) {
        console.error('Max retries reached:', {
          error,
          retryCount,
          operation: operation.name
        });
        throw error;
      }

      const delay = INITIAL_RETRY_DELAY * Math.pow(2, retryCount);
      console.warn('Retrying operation:', {
        retryCount,
        nextRetryDelay: delay,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
      
      await this.sleep(delay);
      return this.retryWithBackoff(operation, retryCount + 1);
    }
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ElevenLabsResponse<T>> {
    const url = `${this.config.baseUrl}${endpoint}`;
    const headers = this.getHeaders();

    return this.retryWithBackoff(async () => {
      try {
        const response = await fetch(url, {
          ...options,
          headers: {
            ...headers,
            ...options.headers,
          },
        });

        if (!response.ok) {
          let errorDetail: string;
          try {
            const errorData = await response.json();
            errorDetail = errorData.detail || `HTTP error! status: ${response.status}`;
          } catch {
            errorDetail = `HTTP error! status: ${response.status}`;
          }

          throw new ElevenLabsClientError(
            errorDetail,
            response.status,
            response.statusText
          );
        }

        const data = await response.json();
        return {
          data,
          status: response.status,
          statusText: response.statusText,
        };
      } catch (error) {
        if (error instanceof ElevenLabsClientError) {
          throw error;
        }
        throw new ElevenLabsClientError(
          'Request failed',
          undefined,
          undefined,
          error
        );
      }
    });
  }

  async pollJob(id: string): Promise<ElevenLabsResponse<TranscriptionJob>> {
    try {
      return await this.request<TranscriptionJob>(`/v1/speech-to-text/${id}`);
    } catch (error) {
      console.error('Failed to poll job:', {
        jobId: id,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
      throw error;
    }
  }

  async downloadResult(id: string): Promise<ElevenLabsResponse<TranscriptionResult>> {
    try {
      return await this.request<TranscriptionResult>(`/v1/speech-to-text/${id}/result`);
    } catch (error) {
      console.error('Failed to download result:', {
        jobId: id,
        error: error instanceof Error ? error.message : 'Unknown error'
      });
      throw error;
    }
  }
} 