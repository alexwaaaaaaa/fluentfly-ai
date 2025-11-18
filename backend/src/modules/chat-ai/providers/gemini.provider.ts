import { Injectable, Logger } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';

export interface AiResponse {
  reply: string;
  emotion: 'happy' | 'neutral' | 'encouraging';
  hint?: string;
}

@Injectable()
export class GeminiProvider {
  private readonly logger = new Logger(GeminiProvider.name);
  private readonly genAI: GoogleGenerativeAI;
  private readonly model: any;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey) {
      this.logger.warn('Gemini API key not configured');
    }

    this.genAI = new GoogleGenerativeAI(apiKey || '');
    this.model = this.genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
  }

  /**
   * Generate AI response using Gemini
   * @param userText - User's input text
   * @param context - Conversation history
   * @returns AI response with reply, emotion, and hint
   */
  async generate(userText: string, context: string[]): Promise<AiResponse> {
    const systemPrompt = `You are FluentFly, an empathetic English tutor for Hindi speakers.
Encourage learners, correct grammar gently, and reply in ≤2 sentences.
Return ONLY valid JSON in this format: {"reply":"...","emotion":"happy|neutral|encouraging","hint":"..."}`;

    const conversationHistory = context.join('\n');
    const prompt = `${systemPrompt}\n\nConversation:\n${conversationHistory}\n\nUser: ${userText}\n\nAssistant:`;

    try {
      this.logger.log(
        `Generating response with Gemini for: ${userText.substring(0, 50)}...`,
      );

      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const text = response.text();

      // Extract JSON from response (handle markdown code blocks)
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error('No JSON found in response');
      }

      const parsed = JSON.parse(jsonMatch[0]);

      this.logger.log('Gemini response generated successfully');

      return {
        reply: parsed.reply,
        emotion: parsed.emotion || 'neutral',
        hint: parsed.hint,
      };
    } catch (error) {
      this.logger.error(`Gemini API error: ${error.message}`);
      throw new Error(`Gemini API error: ${error.message}`);
    }
  }
}
