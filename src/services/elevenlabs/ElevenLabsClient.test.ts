import { ElevenLabsClient, ElevenLabsClientError } from './ElevenLabsClient';
import { TranscriptionJobStatus, TranscriptionResult } from '../../types';

describe('ElevenLabsClient', () => {
  const mockApiKey = 'sk-test-key';
  const mockBaseUrl = 'https://api.elevenlabs.io/v1';

  describe('Configuration', () => {
    it('should throw error when no API key is provided', () => {
      expect(() => new ElevenLabsClient({ apiKey: '' })).toThrow('ElevenLabs API key is required');
    });

    it('should throw error when API key has invalid format', () => {
      expect(() => new ElevenLabsClient({ apiKey: 'invalid-key' }))
        .toThrow('Invalid ElevenLabs API key format');
    });

    it('should initialize with valid API key', () => {
      const client = new ElevenLabsClient({ apiKey: mockApiKey });
      expect(client).toBeInstanceOf(ElevenLabsClient);
    });

    it('should merge provided config with default config', () => {
      const customBaseUrl = 'https://custom-api.elevenlabs.io/v1';
      const client = new ElevenLabsClient({
        apiKey: mockApiKey,
        baseUrl: customBaseUrl,
      });
      expect(client).toBeInstanceOf(ElevenLabsClient);
    });
  });

  describe('Request Headers', () => {
    let client: ElevenLabsClient;
    let mockFetch: jest.Mock;

    beforeEach(() => {
      mockFetch = jest.fn().mockResolvedValue({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve({}),
      });
      global.fetch = mockFetch;
      client = new ElevenLabsClient({ apiKey: mockApiKey });
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should include required headers in requests', async () => {
      await client['request']('/test-endpoint');

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'xi-api-key': mockApiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          }),
        })
      );
    });

    it('should merge custom headers with default headers', async () => {
      const customHeaders = { 'Custom-Header': 'value' };
      await client['request']('/test-endpoint', { headers: customHeaders });

      expect(mockFetch).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'xi-api-key': mockApiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Custom-Header': 'value',
          }),
        })
      );
    });
  });

  describe('Request Retry Logic', () => {
    let client: ElevenLabsClient;
    let mockFetch: jest.Mock;

    beforeEach(() => {
      mockFetch = jest.fn();
      global.fetch = mockFetch;
      client = new ElevenLabsClient({ apiKey: mockApiKey });
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should succeed on first attempt', async () => {
      const mockResponse = { data: 'success' };
      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockResponse),
      });

      const result = await client['request']('/test');
      expect(result.data).toEqual(mockResponse);
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });

    it('should retry on failure and eventually succeed', async () => {
      const mockResponse = { data: 'success' };
      mockFetch
        .mockRejectedValueOnce(new Error('Network error'))
        .mockRejectedValueOnce(new Error('Network error'))
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          statusText: 'OK',
          json: () => Promise.resolve(mockResponse),
        });

      const result = await client['request']('/test');
      expect(result.data).toEqual(mockResponse);
      expect(mockFetch).toHaveBeenCalledTimes(3);
    });

    it('should fail after max retries', async () => {
      const error = new Error('Network error');
      mockFetch.mockRejectedValue(error);

      await expect(client['request']('/test')).rejects.toThrow('Network error');
      expect(mockFetch).toHaveBeenCalledTimes(4); // Initial attempt + 3 retries
    });

    it('should not retry on 4xx client errors', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 400,
        statusText: 'Bad Request',
        json: () => Promise.resolve({ detail: 'Invalid request' }),
      });

      await expect(client['request']('/test')).rejects.toThrow('Invalid request');
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });
  });

  describe('Transcription Job Polling', () => {
    let client: ElevenLabsClient;
    let mockFetch: jest.Mock;

    beforeEach(() => {
      mockFetch = jest.fn();
      global.fetch = mockFetch;
      client = new ElevenLabsClient({ apiKey: mockApiKey });
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should poll job status successfully', async () => {
      const mockJob = {
        id: 'job-123',
        status: 'processing' as TranscriptionJobStatus,
        progress: 45,
        created_at: '2024-03-14T12:00:00Z',
        updated_at: '2024-03-14T12:01:00Z'
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockJob)
      });

      const result = await client.pollJob('job-123');
      expect(result.data).toEqual(mockJob);
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('/v1/speech-to-text/job-123'),
        expect.objectContaining({
          headers: expect.objectContaining({
            'xi-api-key': mockApiKey
          })
        })
      );
    });

    it('should handle failed job status', async () => {
      const mockJob = {
        id: 'job-123',
        status: 'failed' as TranscriptionJobStatus,
        error: 'Transcription failed',
        created_at: '2024-03-14T12:00:00Z',
        updated_at: '2024-03-14T12:01:00Z'
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockJob)
      });

      const result = await client.pollJob('job-123');
      expect(result.data).toEqual(mockJob);
      expect(result.data.status).toBe('failed');
      expect(result.data.error).toBe('Transcription failed');
    });

    it('should handle completed job status', async () => {
      const mockJob = {
        id: 'job-123',
        status: 'completed' as TranscriptionJobStatus,
        progress: 100,
        created_at: '2024-03-14T12:00:00Z',
        updated_at: '2024-03-14T12:01:00Z'
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockJob)
      });

      const result = await client.pollJob('job-123');
      expect(result.data).toEqual(mockJob);
      expect(result.data.status).toBe('completed');
      expect(result.data.progress).toBe(100);
    });

    it('should handle pending job status', async () => {
      const mockJob = {
        id: 'job-123',
        status: 'pending' as TranscriptionJobStatus,
        created_at: '2024-03-14T12:00:00Z',
        updated_at: '2024-03-14T12:01:00Z'
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockJob)
      });

      const result = await client.pollJob('job-123');
      expect(result.data).toEqual(mockJob);
      expect(result.data.status).toBe('pending');
    });
  });

  describe('Result Download', () => {
    let client: ElevenLabsClient;
    let mockFetch: jest.Mock;

    beforeEach(() => {
      mockFetch = jest.fn();
      global.fetch = mockFetch;
      client = new ElevenLabsClient({ apiKey: mockApiKey });
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should download result successfully', async () => {
      const mockResult: TranscriptionResult = {
        text: 'This is the transcribed text',
        segments: [
          {
            text: 'This is the transcribed text',
            start: 0,
            end: 2.5,
            confidence: 0.95
          }
        ]
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockResult)
      });

      const result = await client.downloadResult('job-123');
      expect(result.data).toEqual(mockResult);
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining('/v1/speech-to-text/job-123/result'),
        expect.objectContaining({
          headers: expect.objectContaining({
            'xi-api-key': mockApiKey
          })
        })
      );
    });

    it('should handle empty result', async () => {
      const mockResult: TranscriptionResult = {
        text: '',
        segments: []
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockResult)
      });

      const result = await client.downloadResult('job-123');
      expect(result.data).toEqual(mockResult);
      expect(result.data.text).toBe('');
      expect(result.data.segments).toHaveLength(0);
    });

    it('should handle result with multiple segments', async () => {
      const mockResult: TranscriptionResult = {
        text: 'First segment. Second segment.',
        segments: [
          {
            text: 'First segment.',
            start: 0,
            end: 1.5,
            confidence: 0.95
          },
          {
            text: 'Second segment.',
            start: 1.5,
            end: 3.0,
            confidence: 0.92
          }
        ]
      };

      mockFetch.mockResolvedValueOnce({
        ok: true,
        status: 200,
        statusText: 'OK',
        json: () => Promise.resolve(mockResult)
      });

      const result = await client.downloadResult('job-123');
      expect(result.data).toEqual(mockResult);
      expect(result.data.segments).toHaveLength(2);
      expect(result.data.segments[0].text).toBe('First segment.');
      expect(result.data.segments[1].text).toBe('Second segment.');
    });
  });

  describe('Error Handling', () => {
    let client: ElevenLabsClient;
    let mockFetch: jest.Mock;

    beforeEach(() => {
      mockFetch = jest.fn();
      global.fetch = mockFetch;
      client = new ElevenLabsClient({ apiKey: mockApiKey });
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('should create ElevenLabsClientError with correct properties', () => {
      const error = new ElevenLabsClientError('Test error', 400, 'Bad Request', new Error('Original error'));
      expect(error).toBeInstanceOf(Error);
      expect(error).toBeInstanceOf(ElevenLabsClientError);
      expect(error.message).toBe('Test error');
      expect(error.status).toBe(400);
      expect(error.statusText).toBe('Bad Request');
      expect(error.originalError).toBeInstanceOf(Error);
    });

    it('should not retry on 4xx client errors', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 400,
        statusText: 'Bad Request',
        json: () => Promise.resolve({ detail: 'Invalid request' }),
      });

      await expect(client['request']('/test')).rejects.toThrow('Invalid request');
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });

    it('should handle network errors with retries', async () => {
      const networkError = new Error('Network error');
      mockFetch
        .mockRejectedValueOnce(networkError)
        .mockRejectedValueOnce(networkError)
        .mockResolvedValueOnce({
          ok: true,
          status: 200,
          json: () => Promise.resolve({ data: 'success' }),
        });

      const result = await client['request']('/test');
      expect(result.data).toEqual({ data: 'success' });
      expect(mockFetch).toHaveBeenCalledTimes(3);
    });

    it('should handle JSON parsing errors in error responses', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
        json: () => Promise.reject(new Error('Invalid JSON')),
      });

      await expect(client['request']('/test')).rejects.toThrow('HTTP error! status: 500');
      expect(mockFetch).toHaveBeenCalledTimes(1);
    });

    it('should log errors when polling job fails', async () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      const error = new Error('Polling failed');
      mockFetch.mockRejectedValue(error);

      await expect(client.pollJob('job-123')).rejects.toThrow('Polling failed');
      expect(consoleSpy).toHaveBeenCalledWith('Failed to poll job:', {
        jobId: 'job-123',
        error: 'Polling failed'
      });
      consoleSpy.mockRestore();
    });

    it('should log errors when downloading result fails', async () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
      const error = new Error('Download failed');
      mockFetch.mockRejectedValue(error);

      await expect(client.downloadResult('job-123')).rejects.toThrow('Download failed');
      expect(consoleSpy).toHaveBeenCalledWith('Failed to download result:', {
        jobId: 'job-123',
        error: 'Download failed'
      });
      consoleSpy.mockRestore();
    });
  });
}); 