import { Injectable, Logger } from '@nestjs/common';
import {
  S3Client,
  PutObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';

@Injectable()
export class StorageService {
  private readonly logger = new Logger(StorageService.name);
  private readonly s3Client: S3Client;
  private readonly bucketName: string;
  private readonly cdnUrl: string;

  constructor() {
    this.s3Client = new S3Client({
      region: process.env.S3_REGION || 'auto',
      credentials: {
        accessKeyId: process.env.S3_ACCESS_KEY || '',
        secretAccessKey: process.env.S3_SECRET_KEY || '',
      },
      endpoint: process.env.S3_ENDPOINT,
    });
    this.bucketName = process.env.S3_BUCKET_NAME || 'fluentfly-audio';
    this.cdnUrl = process.env.CDN_URL || process.env.S3_ENDPOINT || '';
  }

  /**
   * Upload audio file to S3/R2 storage
   * @param key - Unique identifier for the audio file (hash)
   * @param buffer - Audio file buffer
   * @returns Public URL of the uploaded audio file
   */
  async uploadAudio(key: string, buffer: Buffer): Promise<string> {
    try {
      const command = new PutObjectCommand({
        Bucket: this.bucketName,
        Key: `audio/${key}.mp3`,
        Body: buffer,
        ContentType: 'audio/mpeg',
        CacheControl: 'max-age=31536000', // 1 year cache
      });

      await this.s3Client.send(command);

      const url = `${this.cdnUrl}/audio/${key}.mp3`;
      this.logger.log(`Audio uploaded successfully: ${key}`);
      return url;
    } catch (error) {
      this.logger.error(`Failed to upload audio: ${key}`, error.stack);
      throw error;
    }
  }

  /**
   * Check if audio file exists in storage
   * @param key - Unique identifier for the audio file (hash)
   * @returns Public URL if exists, null otherwise
   */
  async getAudio(key: string): Promise<string | null> {
    try {
      const command = new HeadObjectCommand({
        Bucket: this.bucketName,
        Key: `audio/${key}.mp3`,
      });

      await this.s3Client.send(command);
      return `${this.cdnUrl}/audio/${key}.mp3`;
    } catch {
      // File doesn't exist
      return null;
    }
  }
}
