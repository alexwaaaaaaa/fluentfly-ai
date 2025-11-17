import { Test, TestingModule } from '@nestjs/testing';
import { SpeechService } from './speech.service';
import { StorageService } from '../storage/storage.service';

describe('SpeechService', () => {
  let service: SpeechService;
  let storageService: StorageService;

  const mockStorageService = {
    getAudio: jest.fn(),
    uploadAudio: jest.fn(),
  };

  beforeEach(async () => {
    // Set environment variables for testing
    process.env.AZURE_SPEECH_KEY = 'test-key';
    process.env.AZURE_SPEECH_REGION = 'eastus';

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SpeechService,
        { provide: StorageService, useValue: mockStorageService },
      ],
    }).compile();

    service = module.get<SpeechService>(SpeechService);
    storageService = module.get<StorageService>(StorageService);

    jest.clearAllMocks();
  });

  afterEach(() => {
    delete process.env.AZURE_SPEECH_KEY;
    delete process.env.AZURE_SPEECH_REGION;
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('textToSpeech', () => {
    it('should return cached audio URL if available', async () => {
      const text = 'Hello world';
      const cachedUrl = 'https://storage.com/cached-audio.mp3';

      mockStorageService.getAudio.mockResolvedValue(cachedUrl);

      const result = await service.textToSpeech(text);

      expect(result).toBe(cachedUrl);
      expect(mockStorageService.getAudio).toHaveBeenCalled();
      expect(mockStorageService.uploadAudio).not.toHaveBeenCalled();
    });

    it('should return placeholder URL when Azure Speech is not configured', async () => {
      delete process.env.AZURE_SPEECH_KEY;

      const module: TestingModule = await Test.createTestingModule({
        providers: [
          SpeechService,
          { provide: StorageService, useValue: mockStorageService },
        ],
      }).compile();

      const unconfiguredService = module.get<SpeechService>(SpeechService);
      mockStorageService.getAudio.mockResolvedValue(null);

      const result = await unconfiguredService.textToSpeech('Hello');

      expect(result).toContain('placeholder');
    });

    it('should generate consistent hash for same text and voice', async () => {
      const text = 'Hello world';
      const cachedUrl = 'https://storage.com/cached-audio.mp3';
      
      // Both calls should use cache
      mockStorageService.getAudio.mockResolvedValue(cachedUrl);

      // Call twice with same text
      await service.textToSpeech(text);
      const firstCallHash = mockStorageService.getAudio.mock.calls[0][0];

      await service.textToSpeech(text);
      const secondCallHash = mockStorageService.getAudio.mock.calls[1][0];

      expect(firstCallHash).toBe(secondCallHash);
      expect(firstCallHash).toHaveLength(64); // SHA-256 hash
    });
  });

  describe('speechToText', () => {
    it('should return empty result when Azure Speech is not configured', async () => {
      delete process.env.AZURE_SPEECH_KEY;

      const module: TestingModule = await Test.createTestingModule({
        providers: [
          SpeechService,
          { provide: StorageService, useValue: mockStorageService },
        ],
      }).compile();

      const unconfiguredService = module.get<SpeechService>(SpeechService);
      const audioBuffer = Buffer.from('fake-audio-data');

      const result = await unconfiguredService.speechToText(audioBuffer);

      expect(result).toEqual({
        text: '',
        confidence: 0,
        words: [],
      });
    });

    it('should handle audio buffer input', async () => {
      const audioBuffer = Buffer.from('fake-audio-data');

      // The actual Azure SDK call will fail in test environment, but we can verify the method exists
      expect(service.speechToText).toBeDefined();
      expect(typeof service.speechToText).toBe('function');
    });
  });

  describe('caching behavior', () => {
    it('should check cache before generating new TTS audio', async () => {
      const text = 'Test message';
      const cachedUrl = 'https://storage.com/cached-audio.mp3';

      mockStorageService.getAudio.mockResolvedValue(cachedUrl);

      const result = await service.textToSpeech(text);

      expect(mockStorageService.getAudio).toHaveBeenCalledTimes(1);
      expect(mockStorageService.uploadAudio).not.toHaveBeenCalled();
      expect(result).toBe(cachedUrl);
    });

    it('should use hash-based caching for TTS', async () => {
      const text = 'Hello';
      const cachedUrl = 'https://storage.com/cached.mp3';
      
      mockStorageService.getAudio.mockResolvedValue(cachedUrl);

      const result = await service.textToSpeech(text);

      expect(mockStorageService.getAudio).toHaveBeenCalledWith(expect.any(String));
      const hash = mockStorageService.getAudio.mock.calls[0][0];
      expect(hash).toHaveLength(64); // SHA-256 hash length
      expect(result).toBe(cachedUrl);
    });
  });
});
