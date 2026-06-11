import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/** Mark a route/resolver as publicly accessible (skip JWT check) */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
