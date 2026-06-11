import { BadRequestException, Injectable } from '@nestjs/common';
import { createHash, randomInt } from 'crypto';
import { SupabaseService } from '../supabase/supabase.service';
import { EmailService } from '../email/email.service';

@Injectable()
export class AuthOtpService {
  private readonly otpPurpose = 'signup';
  private readonly otpTtlMinutes = 10;
  private readonly maxAttempts = 5;
  private readonly rateLimitSeconds = 60;

  constructor(
    private supabase: SupabaseService,
    private emailService: EmailService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  private get otpSecret() {
    return process.env.OTP_SECRET || 'omnigo-otp-secret';
  }

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private hashOtp(email: string, otp: string): string {
    return createHash('sha256')
      .update(`${this.normalizeEmail(email)}:${otp}:${this.otpSecret}`)
      .digest('hex');
  }

  private createOtp(): string {
    return randomInt(100000, 1000000).toString();
  }

  async sendSignUpOtp(email: string, requestIp?: string) {
    const normalizedEmail = this.normalizeEmail(email);

    if (!/^[\w\-.]+@[\w\-]+\.\w+$/.test(normalizedEmail)) {
      throw new BadRequestException('Email không hợp lệ');
    }

    const { data: existingUser } = await this.db
      .from('users')
      .select('id')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (existingUser?.id) {
      throw new BadRequestException('Email đã tồn tại, vui lòng đăng nhập');
    }

    const threshold = new Date(
      Date.now() - this.rateLimitSeconds * 1000,
    ).toISOString();

    const { data: emailRecent } = await this.db
      .from('email_otps')
      .select('id')
      .eq('email', normalizedEmail)
      .eq('purpose', this.otpPurpose)
      .gte('created_at', threshold)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (emailRecent?.id) {
      throw new BadRequestException(
        `Vui lòng chờ ${this.rateLimitSeconds} giây trước khi gửi lại OTP`,
      );
    }

    const normalizedIp = requestIp?.trim();
    if (normalizedIp) {
      const { data: ipRecent } = await this.db
        .from('email_otps')
        .select('id')
        .eq('purpose', this.otpPurpose)
        .eq('request_ip', normalizedIp)
        .gte('created_at', threshold)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (ipRecent?.id) {
        throw new BadRequestException(
          `IP đang gửi quá nhanh. Vui lòng chờ ${this.rateLimitSeconds} giây`,
        );
      }
    }

    const otp = this.createOtp();
    const otpHash = this.hashOtp(normalizedEmail, otp);
    const expiresAt = new Date(Date.now() + this.otpTtlMinutes * 60 * 1000)
      .toISOString();

    await this.db
      .from('email_otps')
      .delete()
      .eq('email', normalizedEmail)
      .eq('purpose', this.otpPurpose)
      .is('used_at', null);

    const { error: insertError } = await this.db.from('email_otps').insert({
      email: normalizedEmail,
      purpose: this.otpPurpose,
      otp_hash: otpHash,
      expires_at: expiresAt,
      request_ip: normalizedIp,
    });

    if (insertError) throw insertError;

    const sent = await this.emailService.sendSignupOtp(
      normalizedEmail,
      otp,
      this.otpTtlMinutes,
    );
    if (!sent) {
      throw new BadRequestException('Không gửi được OTP, vui lòng thử lại');
    }

    return { message: 'OTP đã được gửi', expires_in_minutes: this.otpTtlMinutes };
  }

  async verifySignUpOtp(params: {
    email: string;
    otp: string;
    password: string;
    full_name: string;
  }) {
    const normalizedEmail = this.normalizeEmail(params.email);

    if (params.password.length < 6) {
      throw new BadRequestException('Mật khẩu phải ít nhất 6 ký tự');
    }
    if (!params.full_name.trim()) {
      throw new BadRequestException('Họ tên không được để trống');
    }

    const { data: record, error } = await this.db
      .from('email_otps')
      .select('id, otp_hash, expires_at, attempts, used_at')
      .eq('email', normalizedEmail)
      .eq('purpose', this.otpPurpose)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) throw error;
    if (!record || record.used_at) {
      throw new BadRequestException('OTP không tồn tại hoặc đã dùng');
    }

    const expiresAt = new Date(record.expires_at as string).getTime();
    if (Date.now() > expiresAt) {
      throw new BadRequestException('OTP đã hết hạn');
    }

    if ((record.attempts as number) >= this.maxAttempts) {
      throw new BadRequestException('OTP sai quá nhiều lần, vui lòng gửi lại');
    }

    const expectedHash = this.hashOtp(normalizedEmail, params.otp.trim());
    if (expectedHash !== record.otp_hash) {
      await this.db
        .from('email_otps')
        .update({ attempts: (record.attempts as number) + 1 })
        .eq('id', record.id as string);
      throw new BadRequestException('OTP không đúng');
    }

    const { data: exists } = await this.db
      .from('users')
      .select('id')
      .eq('email', normalizedEmail)
      .maybeSingle();

    if (exists?.id) {
      throw new BadRequestException('Email đã được đăng ký');
    }

    const tenantId =
      process.env.DEFAULT_TENANT_ID ||
      'a0000000-0000-0000-0000-000000000001';

    const { data: created, error: createError } =
      await this.db.auth.admin.createUser({
        email: normalizedEmail,
        password: params.password,
        email_confirm: true,
        user_metadata: { full_name: params.full_name.trim() },
        app_metadata: { tenant_id: tenantId, role: 'customer' },
      });

    if (createError || !created?.user) {
      throw new BadRequestException(
        createError?.message || 'Không thể tạo tài khoản',
      );
    }

    const userId = created.user.id;

    await this.db.from('users').upsert({
      id: userId,
      tenant_id: tenantId,
      full_name: params.full_name.trim(),
      email: normalizedEmail,
      status: 'active',
    });

    const { data: existingCustomer } = await this.db
      .from('customers')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

    if (!existingCustomer?.id) {
      await this.db.from('customers').insert({
        tenant_id: tenantId,
        user_id: userId,
        full_name: params.full_name.trim(),
        email: normalizedEmail,
      });
    }

    await this.db
      .from('email_otps')
      .update({ used_at: new Date().toISOString() })
      .eq('id', record.id as string);

    return { message: 'Xác minh thành công' };
  }
}
