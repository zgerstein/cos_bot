import dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

if (!process.env.ELEVENLABS_API_KEY) {
  console.warn('Warning: ELEVENLABS_API_KEY is not set in environment variables');
}

export const ELEVENLABS_CONFIG = {
  baseUrl: 'https://api.elevenlabs.io/v1',
  // Note: API key should be set via environment variable in production
  apiKey: process.env.ELEVENLABS_API_KEY || '',
}; 