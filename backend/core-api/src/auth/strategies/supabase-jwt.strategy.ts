import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-custom';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';
import { Request } from 'express';

export interface AuthenticatedUser {
  id: string;
  email?: string;
  phone?: string;
  tenantId?: string;
  role: string;
  appMetadata: Record<string, unknown>;
  userMetadata: Record<string, unknown>;
}

@Injectable()
export class SupabaseJwtStrategy extends PassportStrategy(
  Strategy,
  'supabase-jwt',
) {
  private supabaseUrl: string;
  private supabaseAnonKey: string;

  constructor(configService: ConfigService) {
    super();
    this.supabaseUrl = configService.get<string>('supabase.url')!;
    this.supabaseAnonKey = configService.get<string>('supabase.anonKey')!;
  }

  async validate(req: Request): Promise<AuthenticatedUser> {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('No token provided');
    }

    const token = authHeader.split(' ')[1];

    // Verify token via Supabase Auth API (handles ES256, HS256, key rotation)
    const supabase = createClient(this.supabaseUrl, this.supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data?.user) {
      throw new UnauthorizedException('Invalid or expired token');
    }

    const user = data.user;
    // Tenant ID: ưu tiên từ JWT app_metadata, nếu không có thì
    // fallback DEFAULT_TENANT_ID từ env (dev/single-tenant) hoặc demo tenant.
    const fallbackTenantId =
      process.env.DEFAULT_TENANT_ID ||
      'a0000000-0000-0000-0000-000000000001';
    const tenantId =
      (user.app_metadata?.tenant_id as string | undefined) || fallbackTenantId;

    return {
      id: user.id,
      email: user.email,
      phone: user.phone,
      tenantId,
      role: user.role || 'authenticated',
      appMetadata: user.app_metadata || {},
      userMetadata: user.user_metadata || {},
    };
  }
}
