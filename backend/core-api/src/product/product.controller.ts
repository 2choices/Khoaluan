import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
} from '@nestjs/common';
import { ProductService } from './product.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  CreateProductRestDto,
  UpdateProductRestDto,
} from './dto/product-rest.dto';

@Controller('products')
export class ProductController {
  constructor(private productService: ProductService) {}

  @Get()
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query('search') search?: string,
    @Query('category_id') categoryId?: string,
    @Query('is_active') isActive?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.productService.findAll(user.tenantId!, {
      search,
      category_id: categoryId,
      is_active: isActive !== undefined ? isActive === 'true' : undefined,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get('barcode/:barcode')
  findByBarcode(
    @CurrentUser() user: AuthenticatedUser,
    @Param('barcode') barcode: string,
  ) {
    return this.productService.findByBarcode(user.tenantId!, barcode);
  }

  @Get(':id')
  findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.productService.findById(user.tenantId!, id);
  }

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateProductRestDto,
  ) {
    return this.productService.create(user.tenantId!, body);
  }

  @Put(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: UpdateProductRestDto,
  ) {
    return this.productService.update(user.tenantId!, id, body);
  }

  @Delete(':id')
  remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.productService.remove(user.tenantId!, id);
  }

  @Get(':id/variants')
  getVariants(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') productId: string,
  ) {
    return this.productService.findVariantsByProduct(user.tenantId!, productId);
  }

  @Post(':id/variants')
  createVariant(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') productId: string,
    @Body() body: any,
  ) {
    return this.productService.createVariant(user.tenantId!, {
      ...body,
      product_id: productId,
    });
  }

  @Get(':id/units')
  getUnits(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') productId: string,
  ) {
    return this.productService.findUnitsByProduct(user.tenantId!, productId);
  }

  @Post(':id/units')
  createUnit(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') productId: string,
    @Body() body: any,
  ) {
    return this.productService.createUnit(user.tenantId!, {
      ...body,
      product_id: productId,
    });
  }
}