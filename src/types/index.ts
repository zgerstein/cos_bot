export interface ElevenLabsConfig {
  apiKey: string;
  baseUrl?: string;
}

export interface ElevenLabsResponse<T> {
  data: T;
  status: number;
  statusText: string;
}

export interface ElevenLabsError {
  message: string;
  status: number;
  statusText: string;
}

export type TranscriptionJobStatus = 'pending' | 'processing' | 'completed' | 'failed';

export interface TranscriptionJob {
  id: string;
  status: TranscriptionJobStatus;
  progress?: number;
  error?: string;
  created_at: string;
  updated_at: string;
}

export interface TranscriptionSegment {
  text: string;
  start: number;
  end: number;
  confidence: number;
}

export interface TranscriptionResult {
  text: string;
  segments: TranscriptionSegment[];
  language: string;
  duration: number;
  word_count: number;
} 