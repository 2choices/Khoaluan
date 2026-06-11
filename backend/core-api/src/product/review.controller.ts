import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ReviewService } from './review.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('reviews')
export class ReviewController {
  constructor(private reviewService: ReviewService) {}

  @Public()
  @Get('product/:productId')
  listForProduct(
    @Param('productId') productId: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.reviewService.listForProduct(
      productId,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('me')
  listMine(
    @CurrentUser() user: AuthenticatedUser,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.reviewService.listMine(
      user.id,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Get('order/:orderId')
  listForOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
  ) {
    return this.reviewService.listForOrder(user.id, orderId);
  }

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body()
    body: {
      product_id: string;
      order_id?: string;
      rating: number;
      title?: string;
      comment?: string;
    },
  ) {
    return this.reviewService.create(user.tenantId!, user.id, body);
  }
}
