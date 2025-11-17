import { Injectable, Logger } from '@nestjs/common';
import * as sdk from 'microsoft-cognitiveservices-speech-sdk';
import { StorageService } from '../storage/storage.service';
import { SttResponseDto, WordConfidence } from './dto/stt-response.dto';
import * as crypto from 'crypto';

@Injectable()
export class SpeechService {
  private readonly logger = new Logger(SpeechService.name);
  private readonly speechConfig: sdk.SpeechConfig | null;
  private readonly isConfigured: boolean;

  constructor(private readonly storageService: StorageService) {
    const subscriptionKey = process.env.AZURE_SPEECH_KEY;
    const region = process.env.AZURE_SPEECH_REGION || 'eastus';

    if (!subscriptionKey) {
      this.logger.warn('Azure Speech key not configured - Speech services will be disabled');
      this.speechConfig = null;
      this.isConfigured = false;
      return;
    }

    this.speechConfig = sdk.SpeechConfig.fromSubscription(
      subscriptionKey,
      region,
    );

    // Configure TTS voice
    this.speechConfig.speechSynthesisVoiceName = 'en-US-JennyNeural';
    this.isConfigured = true;
  }

  /**
   * Generate hash for caching TTS audio
   * @param text - Text to synthesize
   * @param voice - Voice name
   * @returns Hash string
   */
  private generateHash(text: string, voice: string): string {
    return crypto
      .createHash('sha256')
      .update(`${text}:${voice}`)
      .digest('hex');
  }

  /**
   * Convert text to speech with caching
   * @param text - Text to convert to speech
   * @returns URL of the audio file
   */
  async textToSpeech(text: string): Promise<string> {
    if (!this.isConfigured) {
      this.logger.warn('Azure Speech not configured - returning placeholder URL');
      return 'https://placeholder.com/audio.mp3';
    }

    const voice = 'en-US-JennyNeural';
    const hash = this.generateHash(text, voice);

    // Check if audio already exists in storage
    const cachedUrl = await this.storageService.getAudio(hash);
    if (cachedUrl) {
      this.logger.log(`Using cached TTS audio: ${hash}`);
      return cachedUrl;
    }

    // Generate new audio
    this.logger.log(`Generating TTS audio for: ${text.substring(0, 50)}...`);

    const audioBuffer = await this.synthesizeSpeech(text);

    // Upload to storage
    const url = await this.storageService.uploadAudio(hash, audioBuffer);

    return url;
  }

  /**
   * Synthesize speech using Azure Speech Service
   * @param text - Text to synthesize
   * @returns Audio buffer
   */
  private async synthesizeSpeech(text: string): Promise<Buffer> {
    if (!this.speechConfig) {
      throw new Error('Azure Speech not configured');
    }

    const config = this.speechConfig; // Type narrowing

    return new Promise((resolve, reject) => {
      const synthesizer = new sdk.SpeechSynthesizer(config);

      // Create SSML with cheerful style
      const ssml = `
        <speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" 
               xmlns:mstts="https://www.w3.org/2001/mstts" xml:lang="en-US">
          <voice name="en-US-JennyNeural">
            <mstts:express-as style="cheerful">
              ${this.escapeXml(text)}
            </mstts:express-as>
          </voice>
        </speak>
      `;

      synthesizer.speakSsmlAsync(
        ssml,
        (result) => {
          if (result.reason === sdk.ResultReason.SynthesizingAudioCompleted) {
            this.logger.log('Speech synthesis completed');
            resolve(Buffer.from(result.audioData));
          } else {
            this.logger.error(
              `Speech synthesis failed: ${result.errorDetails}`,
            );
            reject(new Error(`Speech synthesis failed: ${result.errorDetails}`));
          }
          synthesizer.close();
        },
        (error) => {
          this.logger.error('Speech synthesis error', error);
          synthesizer.close();
          reject(error);
        },
      );
    });
  }

  /**
   * Convert speech to text with word-level confidence scores
   * @param audioBuffer - Audio file buffer
   * @returns Transcription with confidence scores
   */
  async speechToText(audioBuffer: Buffer): Promise<SttResponseDto> {
    if (!this.isConfigured || !this.speechConfig) {
      this.logger.warn('Azure Speech not configured - returning empty result');
      return {
        text: '',
        confidence: 0,
        words: [],
      };
    }

    this.logger.log('Processing speech-to-text');

    const config = this.speechConfig; // Type narrowing

    return new Promise((resolve, reject) => {
      // Create push stream for audio input
      const pushStream = sdk.AudioInputStream.createPushStream();
      const arrayBuffer = audioBuffer.buffer.slice(
        audioBuffer.byteOffset,
        audioBuffer.byteOffset + audioBuffer.byteLength,
      ) as ArrayBuffer;
      pushStream.write(arrayBuffer);
      pushStream.close();

      const audioConfig = sdk.AudioConfig.fromStreamInput(pushStream);
      const recognizer = new sdk.SpeechRecognizer(config, audioConfig);

      recognizer.recognizeOnceAsync(
        (result) => {
          if (result.reason === sdk.ResultReason.RecognizedSpeech) {
            this.logger.log(`Recognized: ${result.text}`);

            // Parse detailed results for word-level confidence
            const words = this.parseWordConfidence(result);

            resolve({
              text: result.text,
              confidence: this.calculateOverallConfidence(words),
              words,
            });
          } else if (result.reason === sdk.ResultReason.NoMatch) {
            this.logger.warn('No speech recognized');
            resolve({
              text: '',
              confidence: 0,
              words: [],
            });
          } else {
            this.logger.error(
              `Speech recognition failed: ${result.errorDetails}`,
            );
            reject(new Error(`Speech recognition failed: ${result.errorDetails}`));
          }
          recognizer.close();
        },
        (error) => {
          this.logger.error('Speech recognition error', error);
          recognizer.close();
          reject(error);
        },
      );
    });
  }

  /**
   * Parse word-level confidence from recognition result
   * @param result - Speech recognition result
   * @returns Array of word confidence scores
   */
  private parseWordConfidence(result: sdk.SpeechRecognitionResult): WordConfidence[] {
    try {
      const jsonResult = result.properties.getProperty(
        sdk.PropertyId.SpeechServiceResponse_JsonResult,
      );

      if (!jsonResult) {
        return [];
      }

      const parsed = JSON.parse(jsonResult);
      const nBest = parsed.NBest?.[0];

      if (!nBest?.Words) {
        return [];
      }

      return nBest.Words.map((word: any) => ({
        word: word.Word,
        confidence: word.Confidence || 0,
        offset: word.Offset || 0,
        duration: word.Duration || 0,
      }));
    } catch (error) {
      this.logger.error('Failed to parse word confidence', error);
      return [];
    }
  }

  /**
   * Calculate overall confidence from word-level scores
   * @param words - Array of word confidence scores
   * @returns Overall confidence (0-1)
   */
  private calculateOverallConfidence(words: WordConfidence[]): number {
    if (words.length === 0) return 0;

    const sum = words.reduce((acc, word) => acc + word.confidence, 0);
    return sum / words.length;
  }

  /**
   * Escape XML special characters for SSML
   * @param text - Text to escape
   * @returns Escaped text
   */
  private escapeXml(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }
}
