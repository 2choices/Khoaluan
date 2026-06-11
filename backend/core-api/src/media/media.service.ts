import { Injectable, BadRequestException } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import { Queue } from 'bull';
import { R2Service } from './r2.service';
import { SupabaseService } from '../supabase/supabase.service';
import { v4 as uuid } from 'uuid';
import 'multer';

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_SIZE = 10 * 1024 * 1024; // 10MB

@Injectable()
export class MediaService {
  constructor(
    private r2: R2Service,
    private supabase: SupabaseService,
    @InjectQueue('media-processing') private mediaQueue: Queue,
  ) {}

  async uploadImage(
    tenantId: string,
    file: Express.Multer.File,
    folder = 'products',
  ) {
    // Validate
    if (!ALLOWED_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `File type ${file.mimetype} not allowed. Allowed: ${ALLOWED_TYPES.join(', ')}`,
      );
    }
    if (file.size > MAX_SIZE) {
      throw new BadRequestException(`File too large. Max ${MAX_SIZE / 1024 / 1024}MB`);
    }

    // Generate unique key
    const fileId = uuid();
    const ext = file.originalname.split('.').pop() || 'jpg';
    const key = `${tenantId}/${folder}/${fileId}.${ext}`;

    // Upload original to R2
    const url = await this.r2.upload(key, file.buffer, file.mimetype);

    // Save to DB
    const { data, error } = await this.supabase
      .getAdminClient()
      .from('media')
      .insert({
        tenant_id: tenantId,
        file_name: file.originalname,
        file_path: key,
        file_size: file.size,
        mime_type: file.mimetype,
        url,
        entity_type: folder,
      })
      .select()
      .single();

    if (error) throw error;

    // Queue background processing (WebP, thumbnails, strip EXIF)
    await this.mediaQueue.add('process-image', {
      mediaId: data.id,
      tenantId,
      key,
      mimeType: file.mimetype,
    });

    return data;
  }

  async deleteMedia(tenantId: string, mediaId: string) {
    const db = this.supabase.getAdminClient();

    // Get media record
    const { data: media } = await db
      .from('media')
      .select('file_path')
      .eq('tenant_id', tenantId)
      .eq('id', mediaId)
      .single();

    if (!media) return false;

    // Delete from R2
    await this.r2.delete(media.file_path);

    // Delete thumbnail/small variants if they exist
    const basePath = media.file_path.replace(/\.[^.]+$/, '');
    await this.r2.delete(`${basePath}_thumb.webp`).catch(() => {});
    await this.r2.delete(`${basePath}_small.webp`).catch(() => {});

    // Delete from DB
    await db.from('media').delete().eq('id', mediaId);

    return true;
  }

  /** Get presigned URL for direct client upload */
  async getUploadUrl(tenantId: string, fileName: string, contentType: string) {
    const fileId = uuid();
    const ext = fileName.split('.').pop() || 'jpg';
    const key = `${tenantId}/uploads/${fileId}.${ext}`;

    const presignedUrl = await this.r2.getPresignedUploadUrl(key, contentType);

    return {
      uploadUrl: presignedUrl,
      key,
      publicUrl: this.r2.getPublicUrl(key),
    };
  }
}
