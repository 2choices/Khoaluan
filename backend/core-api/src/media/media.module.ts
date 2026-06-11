import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { MediaService } from './media.service';
import { MediaController } from './media.controller';
import { R2Service } from './r2.service';
import { MediaProcessor } from './media.processor';

@Module({
  imports: [
    BullModule.registerQueue({ name: 'media-processing' }),
  ],
  providers: [MediaService, R2Service, MediaProcessor],
  controllers: [MediaController],
  exports: [MediaService, R2Service],
})
export class MediaModule {}
