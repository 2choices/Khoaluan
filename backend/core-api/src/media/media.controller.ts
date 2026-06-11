import {
  Controller,
  Post,
  Delete,
  Get,
  Param,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { MediaService } from './media.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import 'multer';

@Controller('media')
export class MediaController {
  constructor(private mediaService: MediaService) {}

  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  upload(
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFile() file: Express.Multer.File,
    @Query('folder') folder?: string,
  ) {
    return this.mediaService.uploadImage(
      user.tenantId!,
      file,
      folder || 'products',
    );
  }

  @Get('presign')
  getPresignedUrl(
    @CurrentUser() user: AuthenticatedUser,
    @Query('fileName') fileName: string,
    @Query('contentType') contentType: string,
  ) {
    return this.mediaService.getUploadUrl(
      user.tenantId!,
      fileName,
      contentType,
    );
  }

  @Delete(':id')
  remove(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.mediaService.deleteMedia(user.tenantId!, id);
  }
}
