import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AccessToken } from 'livekit-server-sdk';
import { SpeechService } from '../speech/speech.service';
import { ChatAiService } from '../chat-ai/chat-ai.service';

export interface AgentContext {
  lessonId: number;
  userId: number;
  topic?: string;
  sessionId?: string;
}

export interface ConversationTurn {
  speaker: 'user' | 'ai';
  text: string;
  timestamp: Date;
  audioUrl?: string;
}

/**
 * AI Agent Service for Video Call Interactions
 * 
 * This service manages AI agents that participate in video call sessions with users.
 * It handles:
 * - Agent initialization and token generation
 * - Speech-to-text processing of user audio
 * - AI response generation via ChatAI service
 * - Text-to-speech conversion for AI responses
 * - Conversation history tracking
 * 
 * Architecture Note:
 * The LiveKit server SDK is primarily for token generation and room management.
 * In a production environment, you would need a separate agent process (e.g., using
 * LiveKit Agents framework or a custom WebRTC client) that:
 * 1. Connects to LiveKit rooms using the generated token
 * 2. Subscribes to user audio tracks
 * 3. Processes audio in real-time
 * 4. Publishes AI-generated audio responses
 * 
 * This service provides the backend logic and can be extended to communicate with
 * such agent processes via message queues, WebSockets, or HTTP APIs.
 */
@Injectable()
export class AiAgentService {
  private readonly logger = new Logger(AiAgentService.name);
  private activeAgents: Map<string, { context: AgentContext; token: string }> = new Map();
  private conversationHistory: Map<string, ConversationTurn[]> = new Map();
  private audioBuffers: Map<string, Buffer[]> = new Map();
  private silenceTimers: Map<string, NodeJS.Timeout> = new Map();

  private readonly SILENCE_THRESHOLD_MS = 1000; // 1 second of silence
  private readonly AUDIO_SAMPLE_RATE = 16000; // 16kHz for speech recognition
  private readonly TOKEN_TTL_SECONDS = 3600; // 1 hour

  constructor(
    private readonly configService: ConfigService,
    private readonly speechService: SpeechService,
    private readonly chatAiService: ChatAiService,
  ) {}

  /**
   * Set monitoring service (injected after construction to avoid circular dependency)
   */
  private monitoringService: any;

  setMonitoringService(monitoringService: any): void {
    this.monitoringService = monitoringService;
  }

  /**
   * Spawn an AI agent participant in a LiveKit room
   * Note: This creates the agent metadata and prepares it for connection.
   * In a production environment, this would trigger a separate agent process
   * (e.g., using LiveKit Agents framework) to actually join the room.
   * 
   * @param roomName - The name of the room to join
   * @param context - Context about the lesson and user
   * @returns Promise that resolves when agent is initialized
   */
  async spawnAgent(roomName: string, context: AgentContext): Promise<void> {
    try {
      this.logger.log(
        `Spawning AI agent for room: ${roomName}, lesson: ${context.lessonId}, user: ${context.userId}`,
      );

      // Check if agent already exists for this room
      if (this.activeAgents.has(roomName)) {
        this.logger.warn(`Agent already exists for room: ${roomName}`);
        return;
      }

      // Get LiveKit configuration
      const apiKey = this.configService.get<string>('LIVEKIT_API_KEY');
      const apiSecret = this.configService.get<string>('LIVEKIT_API_SECRET');

      if (!apiKey || !apiSecret) {
        throw new Error('LiveKit configuration not found');
      }

      // Generate token for the AI agent
      const token = await this.generateAgentToken(roomName, apiKey, apiSecret);

      this.logger.log(`AI agent token generated for room: ${roomName}`);

      // Store active agent metadata
      this.activeAgents.set(roomName, { context, token });
      this.conversationHistory.set(roomName, []);
      this.audioBuffers.set(roomName, []);

      // Initialize with greeting
      await this.initializeGreeting(roomName, context);

      this.logger.log(
        `AI agent initialized for room: ${roomName}. Ready to process audio.`,
      );

      // Note: In production, you would trigger an actual agent process here
      // that connects to LiveKit using the generated token and subscribes to tracks.
      // For example:
      // - Spawn a separate Node.js process or container
      // - Use LiveKit Agents framework (Python/Node.js)
      // - Connect via WebSocket to LiveKit and handle real-time audio
    } catch (error) {
      this.logger.error(
        `Failed to spawn AI agent for room ${roomName}: ${error.message}`,
        error.stack,
      );
      throw error;
    }
  }

  /**
   * Generate an access token for the AI agent
   * @param roomName - The name of the room
   * @param apiKey - LiveKit API key
   * @param apiSecret - LiveKit API secret
   * @returns JWT token for the agent
   */
  private async generateAgentToken(
    roomName: string,
    apiKey: string,
    apiSecret: string,
  ): Promise<string> {
    const at = new AccessToken(apiKey, apiSecret, {
      identity: `ai_agent_${roomName}`,
      ttl: '1h',
    });

    at.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
      canPublishData: true,
    });

    return await at.toJwt();
  }



  /**
   * Process incoming audio data from user
   * This method would be called when audio frames are received
   * @param audioData - Raw audio data buffer
   * @param roomName - The name of the room
   * @param context - Context about the lesson and user
   */
  async processAudioData(
    audioData: Buffer,
    roomName: string,
    context: AgentContext,
  ): Promise<void> {
    try {
      // Get or initialize audio buffer for this room
      const buffers = this.audioBuffers.get(roomName) || [];
      buffers.push(audioData);
      this.audioBuffers.set(roomName, buffers);

      // Clear existing silence timer
      const existingTimer = this.silenceTimers.get(roomName);
      if (existingTimer) {
        clearTimeout(existingTimer);
      }

      // Set new silence timer - if no audio for 1 second, process the buffered audio
      const timer = setTimeout(async () => {
        await this.onSilenceDetected(roomName, context);
      }, this.SILENCE_THRESHOLD_MS);

      this.silenceTimers.set(roomName, timer);
    } catch (error) {
      this.logger.error(
        `Error processing audio data for room ${roomName}: ${error.message}`,
      );
    }
  }

  /**
   * Handle silence detection - user has stopped speaking
   * @param roomName - The name of the room
   * @param context - Context about the lesson and user
   */
  private async onSilenceDetected(
    roomName: string,
    context: AgentContext,
  ): Promise<void> {
    try {
      const buffers = this.audioBuffers.get(roomName);
      
      // Check if there's any audio to process
      if (!buffers || buffers.length === 0) {
        return;
      }

      this.logger.log(
        `Silence detected in room ${roomName}. Processing ${buffers.length} audio chunks.`,
      );

      // Combine all audio buffers into one
      const combinedAudio = Buffer.concat(buffers);

      // Clear the buffer for next speech segment
      this.audioBuffers.set(roomName, []);

      // Convert speech to text
      const transcription = await this.speechService.speechToText(combinedAudio);

      if (!transcription.text || transcription.text.trim().length === 0) {
        this.logger.log(`No speech detected in room ${roomName}`);
        return;
      }

      this.logger.log(
        `Transcribed user speech in room ${roomName}: "${transcription.text}"`,
      );

      // Add user's speech to conversation history
      const userTurn: ConversationTurn = {
        speaker: 'user',
        text: transcription.text,
        timestamp: new Date(),
      };

      const history = this.conversationHistory.get(roomName) || [];
      history.push(userTurn);
      this.conversationHistory.set(roomName, history);

      // Generate AI response
      await this.generateAndPublishResponse(
        transcription.text,
        roomName,
        context,
      );
    } catch (error) {
      this.logger.error(
        `Error handling silence detection for room ${roomName}: ${error.message}`,
        error.stack,
      );
    }
  }

  /**
   * Generate AI response and publish it to the room (optimized)
   * @param userText - The user's transcribed speech
   * @param roomName - The name of the room
   * @param context - Context about the lesson and user
   */
  private async generateAndPublishResponse(
    userText: string,
    roomName: string,
    context: AgentContext,
  ): Promise<void> {
    const startTime = Date.now();
    
    try {
      this.logger.log(
        `Generating AI response for user text: "${userText}" in room ${roomName}`,
      );

      // Performance optimization: Run AI generation and TTS in parallel when possible
      const chatResponsePromise = this.chatAiService.processTurn(
        userText,
        context.userId,
        context.sessionId || roomName,
      );

      // Wait for AI response
      const chatResponse = await chatResponsePromise;

      const responseTime = Date.now() - startTime;

      this.logger.log(
        `AI response generated for room ${roomName}: "${chatResponse.reply}" (${responseTime}ms)`,
      );

      // Performance monitoring: Log slow responses
      if (responseTime > 2000) {
        this.logger.warn(
          `Slow AI response detected: ${responseTime}ms for room ${roomName}`,
        );
      }

      // Log response time to monitoring service
      if (this.monitoringService) {
        await this.monitoringService.logAiResponseTime(roomName, responseTime);
      }

      // Add AI response to conversation history
      const aiTurn: ConversationTurn = {
        speaker: 'ai',
        text: chatResponse.reply,
        timestamp: new Date(),
        audioUrl: chatResponse.ttsUrl,
      };

      const history = this.conversationHistory.get(roomName) || [];
      history.push(aiTurn);
      
      // Memory optimization: Keep only last 50 turns
      if (history.length > 50) {
        history.splice(0, history.length - 50);
      }
      
      this.conversationHistory.set(roomName, history);

      // Publish audio response to LiveKit room
      await this.publishAudioToRoom(chatResponse.ttsUrl, roomName);

      this.logger.log(
        `AI response published to room ${roomName}. Total turns: ${history.length}`,
      );
    } catch (error) {
      this.logger.error(
        `Error generating/publishing response for room ${roomName}: ${error.message}`,
        error.stack,
      );

      // Log error to monitoring service
      if (this.monitoringService) {
        await this.monitoringService.logError(
          'ai_response_generation_failed',
          error.message,
          {
            roomName,
            userId: context.userId,
            lessonId: context.lessonId,
          },
        );
      }

      // Send fallback response
      await this.sendFallbackResponse(roomName);
    }
  }

  /**
   * Publish audio to the LiveKit room
   * Note: In production, this would send the audio URL to the agent process
   * which would then download and publish it to the LiveKit room.
   * 
   * @param audioUrl - URL of the audio file to publish
   * @param roomName - The name of the room
   */
  private async publishAudioToRoom(
    audioUrl: string,
    roomName: string,
  ): Promise<void> {
    try {
      const agent = this.activeAgents.get(roomName);
      if (!agent) {
        this.logger.warn(`Agent not found for room ${roomName}`);
        return;
      }

      // In production, you would:
      // 1. Send the audio URL to the agent process via message queue or WebSocket
      // 2. The agent process downloads the audio
      // 3. Converts it to appropriate format (PCM, Opus, etc.)
      // 4. Publishes it as an audio track to LiveKit
      //
      // For now, we log the action as the audio is available via the conversation history

      this.logger.log(
        `Audio ready for publishing to room ${roomName}: ${audioUrl}`,
      );
    } catch (error) {
      this.logger.error(
        `Error preparing audio for room ${roomName}: ${error.message}`,
      );
    }
  }

  /**
   * Send a fallback response when AI generation fails
   * @param roomName - The name of the room
   */
  private async sendFallbackResponse(roomName: string): Promise<void> {
    try {
      const fallbackText =
        "I'm sorry, I didn't quite catch that. Could you please repeat?";

      this.logger.log(`Sending fallback response to room: ${roomName}`);

      // Generate TTS for fallback
      const ttsUrl = await this.speechService.textToSpeech(fallbackText);

      // Add to conversation history
      const turn: ConversationTurn = {
        speaker: 'ai',
        text: fallbackText,
        timestamp: new Date(),
        audioUrl: ttsUrl,
      };

      const history = this.conversationHistory.get(roomName) || [];
      history.push(turn);
      this.conversationHistory.set(roomName, history);

      // Publish to room
      await this.publishAudioToRoom(ttsUrl, roomName);
    } catch (error) {
      this.logger.error(
        `Failed to send fallback response to room ${roomName}: ${error.message}`,
      );
    }
  }

  /**
   * Get conversation turn count for analytics
   * @param roomName - The name of the room
   * @returns Number of conversation turns
   */
  getConversationTurnCount(roomName: string): number {
    const history = this.conversationHistory.get(roomName) || [];
    // Count only complete turns (user + AI pairs)
    return Math.floor(history.length / 2);
  }

  /**
   * Check if agent is active in a room
   * @param roomName - The name of the room
   * @returns True if agent is active
   */
  isAgentActive(roomName: string): boolean {
    return this.activeAgents.has(roomName);
  }

  /**
   * Initialize greeting message for the agent
   * @param roomName - The name of the room
   * @param context - Context about the lesson and user
   */
  private async initializeGreeting(
    roomName: string,
    context: AgentContext,
  ): Promise<void> {
    try {
      const greetingText = context.topic
        ? `Hello! I'm your AI tutor. Let's practice ${context.topic} together. Feel free to start speaking whenever you're ready!`
        : `Hello! I'm your AI tutor. Let's practice English together. Feel free to start speaking whenever you're ready!`;

      this.logger.log(`Initializing greeting for room: ${roomName}`);

      // Generate TTS for greeting
      const ttsUrl = await this.speechService.textToSpeech(greetingText);

      // Add to conversation history
      const turn: ConversationTurn = {
        speaker: 'ai',
        text: greetingText,
        timestamp: new Date(),
        audioUrl: ttsUrl,
      };

      const history = this.conversationHistory.get(roomName) || [];
      history.push(turn);
      this.conversationHistory.set(roomName, history);

      this.logger.log(`Greeting initialized for room: ${roomName}`);
    } catch (error) {
      this.logger.error(
        `Failed to initialize greeting for room ${roomName}: ${error.message}`,
      );
    }
  }

  /**
   * Disconnect the AI agent from a room
   * @param roomName - The name of the room
   */
  async disconnectAgent(roomName: string): Promise<void> {
    try {
      const agent = this.activeAgents.get(roomName);
      if (agent) {
        this.logger.log(`Disconnecting AI agent from room: ${roomName}`);
        // In production, this would signal the agent process to disconnect
        this.cleanup(roomName);
      }
    } catch (error) {
      this.logger.error(
        `Failed to disconnect agent from room ${roomName}: ${error.message}`,
      );
    }
  }

  /**
   * Get conversation history for a room
   * @param roomName - The name of the room
   * @returns Array of conversation turns
   */
  getConversationHistory(roomName: string): ConversationTurn[] {
    return this.conversationHistory.get(roomName) || [];
  }

  /**
   * Clean up resources for a room
   * @param roomName - The name of the room
   */
  private cleanup(roomName: string): void {
    this.activeAgents.delete(roomName);
    this.audioBuffers.delete(roomName);
    
    // Clear any pending silence timers
    const timer = this.silenceTimers.get(roomName);
    if (timer) {
      clearTimeout(timer);
      this.silenceTimers.delete(roomName);
    }

    this.logger.log(`Cleaned up resources for room: ${roomName}`);
  }
}
