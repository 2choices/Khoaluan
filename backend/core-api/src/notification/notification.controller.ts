import { Controller, Get, Post, Patch, Param, Query, Body } from '@nestjs/common';
import { NotificationService } from './notification.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('notifications')
export class NotificationController {
  constructor(private notificationService: NotificationService) {}

  @Get()
  getUserNotifications(
    @CurrentUser() user: AuthenticatedUser,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.notificationService.getUserNotifications(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('unread-count')
  async getUnreadCount(@CurrentUser() user: AuthenticatedUser) {
    const count = await this.notificationService.getUnreadCount(user.id);
    return { count };
  }

  @Post('broadcast')
  broadcast(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: { title: string; body: string; type?: string; audience?: 'all' | 'customers' | 'staff' },
  ) {
    return this.notificationService.broadcast({
      tenantId: user.tenantId!,
      title: body.title,
      body: body.body,
      type: body.type,
      audience: body.audience,
    });
  }

  @Patch(':id/read')
  markAsRead(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.notificationService.markAsRead(user.id, id);
  }

  @Patch('read-all')
  markAllAsRead(@CurrentUser() user: AuthenticatedUser) {
    return this.notificationService.markAllAsRead(user.id);
  }
}
