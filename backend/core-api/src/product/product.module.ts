import { Module } from '@nestjs/common';
import { ProductService } from './product.service';
import { ProductResolver } from './product.resolver';
import { ProductController } from './product.controller';
import { CategoryService } from './category.service';
import { CategoryResolver } from './category.resolver';
import { CategoryController } from './category.controller';
import { ReviewService } from './review.service';
import { ReviewController } from './review.controller';

@Module({
  providers: [
    ProductService,
    ProductResolver,
    CategoryService,
    CategoryResolver,
    ReviewService,
  ],
  controllers: [ProductController, CategoryController, ReviewController],
  exports: [ProductService, CategoryService, ReviewService],
})
export class ProductModule {}
