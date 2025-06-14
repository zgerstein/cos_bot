Phase 2 PRD – ElevenLabs Voice-Clone / TTS Integration
1. Introduction / Overview
Phase 2 uses ElevenLabs’ Speech-to-Text (STT) API. After each recording finishes, the app will upload the .m4a file to ElevenLabs, poll for completion, download the transcript, and save it locally.
Goal: give users an accurate, vendor-hosted transcript of every meeting with zero manual steps.

The goal is to automate Upload → Generate transcript → Download transcript with minimal user input.

2. Functional Requirements
1.1 The ElevenLabs API key will be hardcoded. the user doesn't need to enter it in a UI
1.2 Add a button in the app after a recoding is stopped for user to trigger the firing of the audio file to elevenlabs. this will eventually be automated, but keep as a button for testing.

FR-2 – Client Library
2.1 The system must implement ElevenLabsClient that performs authenticated requests (Authorization: Bearer <key>).
2.2 The client must expose methods: createVoiceClone(), uploadAudio(url:), requestTTS(text:), pollJob(id:), downloadResult(id:).

FR-3 – Upload Pipeline
3.1 When a recording stops, if transcription is enabled, the system must POST the file to POST /v1/speech-to-text (multipart/form-data).
3.2 The system must retry transient network failures up to 3 times with exponential back-off.

FR-4 – Job Monitoring
3.1 The system must parse the returned job_id and poll GET /v1/speech-to-text/{job_id} every 10 s.
4.2 Polling must stop when status == "completed" or "failed"; on failure, surface a banner with Retry.

FR-5 – Download & Storage
5.1 On completion the system must download the transcript JSON.
5.2 It must create two local files in the recording folder:
  • Recording-YYYYMMDD-HHMMSS.json (raw payload)
  • Recording-YYYYMMDD-HHMMSS.txt (plain text)


FR-6 – UI Feedback
6.1 Display a circular progress ring and label (“Transcribing… 45 %”) beside the recording.
6.2 Fire a Notification Center toast (“Transcript ready – Open”) that opens the text file in the default editor.

FR-7 – Error Handling
7.1 All network errors must retry up to 3× with exponential back-off.
7.2 If polling exceeds 10 min, mark status Timed Out and log to Sentry.

5. Non-Goals (Out of Scope)
Summarisation or action-item extraction (Phase 4).

Text-to-speech or voice cloning.

Real-time/streaming transcription during the meeting.

Support for alternative STT vendors in this phase.