import { Body, Controller, Post, Req } from '@nestjs/common';
import type { Request } from 'express';
import { Public } from './decorators/public.decorator';
import { AuthOtpService } from './auth-otp.service';

@Controller('auth')
export class AuthOtpController {
  constructor(private authOtpService: AuthOtpService) {}

  private getRequestIp(req: Request): string | undefined {
    const forwarded = req.headers['x-forwarded-for'];
    if (typeof forwarded === 'string' && forwarded.trim().length > 0) {
      return forwarded.split(',')[0]?.trim();
    }
    const realIp = req.headers['x-real-ip'];
    if (typeof realIp === 'string' && realIp.trim().length > 0) {
      return realIp.trim();
    }
    return req.ip || undefined;
  }

  @Public()
  @Post('signup-otp/send')
  sendOtp(@Body() body: { email: string }, @Req() req: Request) {
    return this.authOtpService.sendSignUpOtp(
      body.email || '',
      this.getRequestIp(req),
    );
  }

  @Public()
  @Post('signup-otp/verify')
  verifyOtp(
    @Body()
    body: {
      email: string;
      otp: string;
      password: string;
      full_name: string;
    },
  ) {
    return this.authOtpService.verifySignUpOtp(body);
  }
}
