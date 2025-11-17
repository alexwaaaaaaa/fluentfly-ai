import { IsString, IsNotEmpty, Length, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class VerifyOtpDto {
  @ApiProperty({
    description: 'Phone number in E.164 format',
    example: '+919876543210',
  })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiProperty({
    description: '6-digit OTP code',
    example: '123456',
  })
  @IsString()
  @IsNotEmpty()
  @Length(6, 6, { message: 'OTP must be exactly 6 digits' })
  otp: string;

  @ApiProperty({
    description: 'User name for new users',
    example: 'John Doe',
    required: false,
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({
    description: 'Learning purpose for new users',
    example: 'Career Growth',
    required: false,
  })
  @IsOptional()
  @IsString()
  learningPurpose?: string;

  @ApiProperty({
    description: 'English proficiency level for new users',
    example: 'beginner',
    required: false,
  })
  @IsOptional()
  @IsString()
  englishLevel?: string;
}
