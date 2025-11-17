import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UnauthorizedException, BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { RedisService } from '../../common/redis/redis.service';
import { User } from '../users/entities/user.entity';

describe('AuthService', () => {
  let service: AuthService;
  let usersService: UsersService;
  let jwtService: JwtService;
  let redisService: RedisService;
  let configService: ConfigService;

  const mockUser: User = {
    id: 1,
    email: 'test@example.com',
    phone: null,
    name: 'Test User',
    xp: 100,
    streak: 5,
    level: 'A2',
    lastActiveDate: new Date(),
    profileImageUrl: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockUsersService = {
    findByEmail: jest.fn(),
    findByPhone: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    updateLastActive: jest.fn(),
  };

  const mockJwtService = {
    sign: jest.fn(),
    verify: jest.fn(),
  };

  const mockRedisService = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((key: string) => {
      const config: Record<string, string> = {
        JWT_SECRET: 'test-secret',
        JWT_REFRESH_SECRET: 'test-refresh-secret',
        JWT_EXPIRATION: '7d',
      };
      return config[key];
    }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: RedisService, useValue: mockRedisService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(UsersService);
    jwtService = module.get<JwtService>(JwtService);
    redisService = module.get<RedisService>(RedisService);
    configService = module.get<ConfigService>(ConfigService);

    // Clear all mocks
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('sendOtp', () => {
    it('should generate and store OTP successfully', async () => {
      const phone = '+1234567890';
      mockRedisService.get.mockResolvedValue(null);
      mockRedisService.set.mockResolvedValue('OK');

      const result = await service.sendOtp(phone);

      expect(result).toEqual({ success: true });
      expect(mockRedisService.set).toHaveBeenCalledTimes(2); // OTP and rate limit
      expect(mockRedisService.set).toHaveBeenCalledWith(
        `otp:${phone}`,
        expect.any(String),
        600,
      );
    });

    it('should enforce rate limiting after 5 attempts', async () => {
      const phone = '+1234567890';
      mockRedisService.get.mockResolvedValue('5');

      await expect(service.sendOtp(phone)).rejects.toThrow(BadRequestException);
      await expect(service.sendOtp(phone)).rejects.toThrow(
        'Too many OTP requests',
      );
    });

    it('should increment rate limit counter', async () => {
      const phone = '+1234567890';
      mockRedisService.get.mockResolvedValue('2');
      mockRedisService.set.mockResolvedValue('OK');

      await service.sendOtp(phone);

      expect(mockRedisService.set).toHaveBeenCalledWith(
        `otp:ratelimit:${phone}`,
        '3',
        900,
      );
    });
  });

  describe('verifyOtp', () => {
    it('should verify OTP and create new user', async () => {
      const phone = '+1234567890';
      const otp = '123456';
      const name = 'New User';

      mockRedisService.get.mockResolvedValue(otp);
      mockRedisService.del.mockResolvedValue(1);
      mockUsersService.findByPhone.mockResolvedValue(null);
      mockUsersService.create.mockResolvedValue(mockUser);
      mockJwtService.sign.mockReturnValue('mock-token');

      const result = await service.verifyOtp({ phone, otp, name });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result).toHaveProperty('user');
      expect(mockUsersService.create).toHaveBeenCalledWith({
        phone,
        name,
      });
      expect(mockRedisService.del).toHaveBeenCalledWith(`otp:${phone}`);
    });

    it('should verify OTP and return existing user', async () => {
      const phone = '+1234567890';
      const otp = '123456';

      mockRedisService.get.mockResolvedValue(otp);
      mockRedisService.del.mockResolvedValue(1);
      mockUsersService.findByPhone.mockResolvedValue(mockUser);
      mockUsersService.updateLastActive.mockResolvedValue(undefined);
      mockJwtService.sign.mockReturnValue('mock-token');

      const result = await service.verifyOtp({ phone, otp });

      expect(result).toHaveProperty('accessToken');
      expect(mockUsersService.updateLastActive).toHaveBeenCalledWith(mockUser.id);
    });

    it('should throw error for expired OTP', async () => {
      const phone = '+1234567890';
      const otp = '123456';

      mockRedisService.get.mockResolvedValue(null);

      await expect(service.verifyOtp({ phone, otp })).rejects.toThrow(
        UnauthorizedException,
      );
      await expect(service.verifyOtp({ phone, otp })).rejects.toThrow(
        'OTP expired or not found',
      );
    });

    it('should throw error for invalid OTP', async () => {
      const phone = '+1234567890';
      const otp = '123456';

      mockRedisService.get.mockResolvedValue('654321');

      await expect(service.verifyOtp({ phone, otp })).rejects.toThrow(
        UnauthorizedException,
      );
      await expect(service.verifyOtp({ phone, otp })).rejects.toThrow(
        'Invalid OTP',
      );
    });
  });

  describe('refreshToken', () => {
    it('should generate new tokens from valid refresh token', async () => {
      const refreshToken = 'valid-refresh-token';
      const payload = { sub: 1, email: 'test@example.com' };

      mockJwtService.verify.mockReturnValue(payload);
      mockUsersService.findOne.mockResolvedValue(mockUser);
      mockJwtService.sign.mockReturnValue('new-token');

      const result = await service.refreshToken(refreshToken);

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(mockJwtService.verify).toHaveBeenCalledWith(refreshToken, {
        secret: 'test-refresh-secret',
      });
    });

    it('should throw error for invalid refresh token', async () => {
      const refreshToken = 'invalid-token';

      mockJwtService.verify.mockImplementation(() => {
        throw new Error('Invalid token');
      });

      await expect(service.refreshToken(refreshToken)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe('validateUser', () => {
    it('should return user by ID', async () => {
      mockUsersService.findOne.mockResolvedValue(mockUser);

      const result = await service.validateUser(1);

      expect(result).toEqual(mockUser);
      expect(mockUsersService.findOne).toHaveBeenCalledWith(1);
    });
  });
});
