import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private adminClient!: SupabaseClient;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const url = this.configService.get<string>('supabase.url');
    const serviceRoleKey = this.configService.get<string>(
      'supabase.serviceRoleKey',
    );

    if (!url || !serviceRoleKey) {
      throw new Error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    }

    this.adminClient = createClient(url, serviceRoleKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
  }

  /** Service-role client (bypasses RLS) */
  getAdminClient(): SupabaseClient {
    return this.adminClient;
  }

  /** Client scoped to a specific user's JWT (respects RLS) */
  getClientForUser(accessToken: string): SupabaseClient {
    const url = this.configService.get<string>('supabase.url')!;
    const anonKey = this.configService.get<string>('supabase.anonKey')!;

    return createClient(url, anonKey, {
      global: {
        headers: { Authorization: `Bearer ${accessToken}` },
      },
      auth: { autoRefreshToken: false, persistSession: false },
    });
  }
}
