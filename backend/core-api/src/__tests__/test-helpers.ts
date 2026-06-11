/** Shared test mocks for Supabase, Config, Redis */

export const mockSupabaseClient = {
  from: jest.fn().mockReturnThis(),
  select: jest.fn().mockReturnThis(),
  insert: jest.fn().mockReturnThis(),
  update: jest.fn().mockReturnThis(),
  delete: jest.fn().mockReturnThis(),
  eq: jest.fn().mockReturnThis(),
  neq: jest.fn().mockReturnThis(),
  in: jest.fn().mockReturnThis(),
  gte: jest.fn().mockReturnThis(),
  lte: jest.fn().mockReturnThis(),
  lt: jest.fn().mockReturnThis(),
  gt: jest.fn().mockReturnThis(),
  filter: jest.fn().mockReturnThis(),
  not: jest.fn().mockReturnThis(),
  is: jest.fn().mockReturnThis(),
  like: jest.fn().mockReturnThis(),
  ilike: jest.fn().mockReturnThis(),
  or: jest.fn().mockReturnThis(),
  order: jest.fn().mockReturnThis(),
  range: jest.fn().mockReturnThis(),
  limit: jest.fn().mockReturnThis(),
  single: jest.fn().mockReturnThis(),
  maybeSingle: jest.fn().mockReturnThis(),
  rpc: jest.fn(),
};

export const mockSupabaseService = {
  getAdminClient: jest.fn().mockReturnValue(mockSupabaseClient),
  getClientForUser: jest.fn().mockReturnValue(mockSupabaseClient),
};

export const mockConfigService = {
  get: jest.fn((key: string, defaultValue?: any) => defaultValue || ''),
};

export const mockRedisService = {
  get: jest.fn().mockResolvedValue(null),
  set: jest.fn().mockResolvedValue(undefined),
  del: jest.fn().mockResolvedValue(undefined),
  delPattern: jest.fn().mockResolvedValue(undefined),
};

export function resetAllMocks() {
  Object.values(mockSupabaseClient).forEach((fn) => {
    if (typeof fn === 'function' && 'mockClear' in fn) {
      (fn as jest.Mock).mockReset();
      (fn as jest.Mock).mockReturnThis();
    }
  });
  Object.values(mockRedisService).forEach((fn) => {
    if (typeof fn === 'function' && 'mockReset' in fn) {
      (fn as jest.Mock).mockReset();
    }
  });
  mockRedisService.get.mockResolvedValue(null);
  mockRedisService.set.mockResolvedValue(undefined);
  mockRedisService.del.mockResolvedValue(undefined);
  mockRedisService.delPattern.mockResolvedValue(undefined);
  mockSupabaseService.getAdminClient.mockReturnValue(mockSupabaseClient);
  mockSupabaseService.getClientForUser.mockReturnValue(mockSupabaseClient);
  mockConfigService.get.mockReset();
  mockConfigService.get.mockImplementation((key: string, defaultValue?: any) => defaultValue || '');
}
