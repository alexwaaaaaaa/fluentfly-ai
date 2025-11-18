import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { UsersService } from '../users/users.service';
import { User } from '../users/entities/user.entity';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { AuthResponseDto } from './dto/auth-response.dto';
import { RedisService } from '../../common/redis/redis.service';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private firebaseApp: admin.app.App;

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly redisService: RedisService,
  ) {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      // Check if Firebase is already initialized
      if (admin.apps.length === 0) {
        const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
        const privateKey = this.configService
          .get<string>('FIREBASE_PRIVATE_KEY')
          ?.replace(/\\n/g, '\n');
        const clientEmail = this.configService.get<string>(
          'FIREBASE_CLIENT_EMAIL',
        );

        if (!projectId || !privateKey || !clientEmail) {
          this.logger.warn(
            'Firebase credentials not configured. Phone OTP will not work.',
          );
          return;
        }

        this.firebaseApp = admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            privateKey,
            clientEmail,
          }),
        });
        this.logger.log('Firebase Admin SDK initialized successfully');
      } else {
        this.firebaseApp = admin.app();
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin SDK', error);
    }
  }

  async googleAuth(googleAuthDto: GoogleAuthDto): Promise<AuthResponseDto> {
    try {
      // Verify the Google ID token using Firebase Admin SDK
      const decodedToken = await admin
        .auth()
        .verifyIdToken(googleAuthDto.idToken);

      const email = decodedToken.email;
      const name = decodedToken.name || 'User';
      const profileImageUrl = decodedToken.picture;

      if (!email) {
        throw new UnauthorizedException('Email not found in Google token');
      }

      // Find or create user
      let user = await this.usersService.findByEmail(email);

      if (!user) {
        user = await this.usersService.create({
          email,
          name,
          profileImageUrl,
        });
        this.logger.log(`New user created via Google OAuth: ${email}`);
      } else {
        // Update last active date
        await this.usersService.updateLastActive(user.id);
      }

      return this.generateAuthResponse(user);
    } catch (error) {
      this.logger.error('Google authentication failed', error);
      throw new UnauthorizedException('Invalid Google token');
    }
  }

  async sendOtp(phone: string): Promise<{ success: boolean }> {
    try {
      // Validate phone number format
      if (!phone || phone.length < 10) {
        throw new BadRequestException('Invalid phone number format');
      }

      // Check rate limiting - max 5 OTP requests per 15 minutes
      const rateLimitKey = `otp:ratelimit:${phone}`;
      let attempts: string | null = null;

      try {
        attempts = await this.redisService.get(rateLimitKey);
      } catch (redisError) {
        this.logger.warn(
          'Redis unavailable for rate limiting, continuing without it',
          redisError,
        );
      }

      if (attempts && parseInt(attempts) >= 5) {
        throw new BadRequestException(
          'Too many OTP requests. Please try again after 15 minutes.',
        );
      }

      // Generate 6-digit OTP
      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      // Store OTP in Redis with 15-minute expiration
      const otpKey = `otp:${phone}`;
      try {
        await this.redisService.set(otpKey, otp, 900); // 15 minutes

        // Increment rate limit counter
        const currentAttempts = attempts ? parseInt(attempts) + 1 : 1;
        await this.redisService.set(
          rateLimitKey,
          currentAttempts.toString(),
          900,
        ); // 15 minutes
      } catch (redisError) {
        this.logger.error(
          'Redis error storing OTP, falling back to in-memory',
          redisError,
        );
        // In production, you might want to use an in-memory fallback
        // For now, we'll continue but log the error
      }

      // In production, send OTP via SMS service (Twilio, AWS SNS, etc.)
      // For development, log the OTP
      this.logger.log(`OTP for ${phone}: ${otp}`);

      return { success: true };
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Failed to send OTP', error);
      throw new BadRequestException('Failed to send OTP. Please try again.');
    }
  }

  async verifyOtp(verifyOtpDto: VerifyOtpDto): Promise<AuthResponseDto> {
    const { phone, otp, name, learningPurpose, englishLevel } = verifyOtpDto;

    // Get stored OTP from Redis
    const otpKey = `otp:${phone}`;
    let storedOtp: string | null = null;

    try {
      storedOtp = await this.redisService.get(otpKey);
    } catch (redisError) {
      this.logger.error('Redis error retrieving OTP', redisError);
      throw new UnauthorizedException('OTP verification service unavailable');
    }

    if (!storedOtp) {
      throw new UnauthorizedException('OTP expired or not found');
    }

    // Debug logging
    this.logger.debug(
      `Comparing OTPs - Stored: "${storedOtp}" (type: ${typeof storedOtp}), Received: "${otp}" (type: ${typeof otp})`,
    );

    if (storedOtp !== otp) {
      this.logger.warn(
        `OTP mismatch - Stored: "${storedOtp}", Received: "${otp}"`,
      );
      throw new UnauthorizedException('Invalid OTP');
    }

    // Delete OTP after successful verification
    try {
      await this.redisService.del(otpKey);
    } catch (redisError) {
      this.logger.warn('Failed to delete OTP from Redis', redisError);
      // Continue anyway since verification was successful
    }

    // Find or create user
    let user = await this.usersService.findByPhone(phone);

    if (!user) {
      user = await this.usersService.create({
        phone,
        name: name || 'User',
        learningPurpose,
        englishLevel,
      });
      this.logger.log(`New user created via phone OTP: ${phone}`);
    } else {
      // Update last active date
      await this.usersService.updateLastActive(user.id);
    }

    return this.generateAuthResponse(user);
  }

  async refreshToken(refreshToken: string): Promise<AuthResponseDto> {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });

      const user = await this.usersService.findOne(payload.sub);
      return this.generateAuthResponse(user);
    } catch (error) {
      this.logger.error('Token refresh failed', error);
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async validateUser(userId: number): Promise<User> {
    return this.usersService.findOne(userId);
  }

  private generateAuthResponse(user: User): AuthResponseDto {
    const payload = { sub: user.id, email: user.email, phone: user.phone };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_SECRET'),
      expiresIn: this.configService.get<string>('JWT_EXPIRATION') || '7d',
    } as any);

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: '30d',
    } as any);

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        email: user.email,
        phone: user.phone,
        name: user.name,
        xp: user.xp,
        streak: user.streak,
        level: user.level,
      },
    };
  }
}
