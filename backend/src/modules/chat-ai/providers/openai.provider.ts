import { Injectable, Logger } from '@nestjs/common';
import OpenAI from 'openai';
import { AiResponse } from './gemini.provider';

@Injectable()
export class OpenAiProvider {
  private readonly logger = new Logger(OpenAiProvider.name);
  private readonly client: OpenAI;

  constructor() {
    const apiKey = process.env.OPENAI_API_KEY;

    if (!apiKey) {
      this.logger.warn('OpenAI API key not configured');
    }

    this.client = new OpenAI({
      apiKey: apiKey || '',
    });
  }

  /**
   * Generate AI response using OpenAI
   * @param userText - User's input text
   * @param context - Conversation history
   * @returns AI response with reply, emotion, and hint
   */
  async generate(userText: string, context: string[]): Promise<AiResponse> {
    const systemPrompt = `You are FluentFly, an empathetic English tutor for Hindi speakers.
Encourage learners, correct grammar gently, and reply in ≤2 sentences.
Return ONLY valid JSON in this format: {"reply":"...","emotion":"happy|neutral|encouraging","hint":"..."}`;

    const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
      { role: 'system', content: systemPrompt },
    ];

    // Add conversation history
    context.forEach((msg, i) => {
      messages.push({
        role: i % 2 === 0 ? 'user' : 'assistant',
        content: msg,
      });
    });

    // Add current user message
    messages.push({ role: 'user', content: userText });

    try {
      this.logger.log(`Generating response with OpenAI for: ${userText.substring(0, 50)}...`);

      const completion = await this.client.chat.completions.create({
        model: 'gpt-4o-mini',
        messages,
        temperature: 0.7,
        max_tokens: 150,
        response_format: { type: 'json_object' },
      });

      const content = completion.choices[0].message.content;
      if (!content) {
        throw new Error('No content in OpenAI response');
      }

      const parsed = JSON.parse(content);

      this.logger.log('OpenAI response generated successfully');

      return {
        reply: parsed.reply,
        emotion: parsed.emotion || 'neutral',
        hint: parsed.hint,
      };
    } catch (error) {
      this.logger.error(`OpenAI API error: ${error.message}`);
      throw new Error(`OpenAI API error: ${error.message}`);
    }
  }
}
