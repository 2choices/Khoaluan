import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class R2Service implements OnModuleInit {
  private client!: S3Client;
  private bucket!: string;
  private publicUrl!: string;
  private readonly logger = new Logger(R2Service.name);

  constructor(private config: ConfigService) {}

  onModuleInit() {
    this.bucket = this.config.get<string>('R2_BUCKET_PUBLIC', 'omnigo-media');
    this.publicUrl = this.config.get<string>('R2_PUBLIC_URL', '');

    this.client = new S3Client({
      region: 'auto',
      endpoint: this.config.get<string>('R2_ENDPOINT'),
      credentials: {
        accessKeyId: this.config.get<string>('R2_ACCESS_KEY_ID', ''),
        secretAccessKey: this.config.get<string>('R2_SECRET_ACCESS_KEY', ''),
      },
    });

    this.logger.log('R2 client initialized');
  }

  /** Upload a file buffer to R2 */
  async upload(
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<string> {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );

    return this.getPublicUrl(key);
  }

  /** Delete a file from R2 */
  async delete(key: string): Promise<void> {
    await this.client.send(
      new DeleteObjectCommand({
        Bucket: this.bucket,
        Key: key,
      }),
    );
  }

  /** Generate a presigned URL for direct upload */
  async getPresignedUploadUrl(
    key: string,
    contentType: string,
    expiresIn = 3600,
  ): Promise<string> {
    return getSignedUrl(
      this.client,
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        ContentType: contentType,
      }),
      { expiresIn },
    );
  }

  /** Get public CDN URL */
  getPublicUrl(key: string): string {
    if (this.publicUrl) {
      return `${this.publicUrl}/${key}`;
    }
    return `https://${this.bucket}.r2.dev/${key}`;
  }
}
