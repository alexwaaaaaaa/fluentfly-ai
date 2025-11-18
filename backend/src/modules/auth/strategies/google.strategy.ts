import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-google-oauth20';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class GoogleStrategy extends PassportStrategy(Strategy, 'google') {
  constructor(private configService: ConfigService) {
    super({
      clientID:
        configService.get<string>('GOOGLE_CLIENT_ID') || 'default-client-id',
      clientSecret:
        configService.get<string>('GOOGLE_CLIENT_SECRET') || 'default-secret',
      callbackURL:
        configService.get<string>('GOOGLE_CALLBACK_URL') ||
        'http://localhost:3000/api/auth/google/callback',
      scope: ['email', 'profile'],
    });
  }

  async validate(
    accessToken: string,
    refreshToken: string,
    profile: any,
  ): Promise<any> {
    const { name, emails, photos } = profile;

    if (!emails || emails.length === 0) {
      throw new UnauthorizedException('No email found in Google profile');
    }

    return {
      email: emails[0].value,
      name: name.givenName + ' ' + name.familyName,
      profileImageUrl: photos?.[0]?.value,
    };
  }
}
