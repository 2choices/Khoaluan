import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import { Job } from 'bull';
import sharp from 'sharp';
import { R2Service } from './r2.service';
import { SupabaseService } from '../supabase/supabase.service';

interface ProcessImageJob {
  mediaId: string;
  tenantId: string;
  key: string;
  mimeType: string;
}

@Processor('media-processing')
export class MediaProcessor {
  private readonly logger = new Logger(MediaProcessor.name);

  constructor(
    private r2: R2Service,
    private supabase: SupabaseService,
  ) {}

  @Process('process-image')
  async processImage(job: Job<ProcessImageJob>) {
    const { mediaId, tenantId, key } = job.data;
    this.logger.log(`Processing image: ${key}`);

    try {
      // Download original from R2
      const url = this.r2.getPublicUrl(key);
      const response = await fetch(url);
      const buffer = Buffer.from(await response.arrayBuffer());

      const basePath = key.replace(/\.[^.]+$/, '');

      // Generate thumbnail (200px)
      const thumbBuffer = await sharp(buffer)
        .resize(200, 200, { fit: 'cover' })
        .webp({ quality: 80 })
        .toBuffer();

      const thumbKey = `${basePath}_thumb.webp`;
      const thumbUrl = await this.r2.upload(thumbKey, thumbBuffer, 'image/webp');

      // Generate small (400px)
      const smallBuffer = await sharp(buffer)
        .resize(400, 400, { fit: 'inside', withoutEnlargement: true })
        .webp({ quality: 85 })
        .toBuffer();

      const smallKey = `${basePath}_small.webp`;
      const smallUrl = await this.r2.upload(smallKey, smallBuffer, 'image/webp');

      // Generate optimized WebP of original size
      const webpBuffer = await sharp(buffer)
        .webp({ quality: 85 })
        .toBuffer();

      const webpKey = `${basePath}.webp`;
      if (!key.endsWith('.webp')) {
        await this.r2.upload(webpKey, webpBuffer, 'image/webp');
      }

      // Update media record with processed URLs
      await this.supabase
        .getAdminClient()
        .from('media')
        .update({
          thumbnail_url: thumbUrl,
          processed: true,
        })
        .eq('id', mediaId);

      this.logger.log(`Image processed: ${key} → thumb + small + webp`);
    } catch (err) {
      this.logger.error(`Failed to process image ${key}`, (err as Error).stack);
      throw err;
    }
  }
}
