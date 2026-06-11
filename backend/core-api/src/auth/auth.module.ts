import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { SupabaseJwtStrategy } from './strategies/supabase-jwt.strategy';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { SupabaseModule } from '../supabase/supabase.module';
import { EmailModule } from '../email/email.module';
import { AuthOtpService } from './auth-otp.service';
import { AuthOtpController } from './auth-otp.controller';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'supabase-jwt' }),
    SupabaseModule,
    EmailModule,
  ],
  providers: [SupabaseJwtStrategy, JwtAuthGuard, AuthOtpService],
  controllers: [AuthOtpController],
  exports: [JwtAuthGuard, PassportModule],
})
export class AuthModule {}
