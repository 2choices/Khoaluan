import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { ProductService } from './product.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  Product,
  ProductVariant,
  ProductUnit,
  ProductImage,
  PaginatedProducts,
  CreateProductInput,
  UpdateProductInput,
  ProductFilterInput,
  CreateVariantInput,
  UpdateVariantInput,
  CreateUnitInput,
  UpdateUnitInput,
} from './dto/product.types';

@Resolver(() => Product)
export class ProductResolver {
  constructor(private productService: ProductService) {}

  // ---- Products ----

  @Query(() => PaginatedProducts)
  async products(
    @CurrentUser() user: AuthenticatedUser,
    @Args('filter', { nullable: true }) filter?: ProductFilterInput,
  ) {
    return this.productService.findAll(user.tenantId!, filter);
  }

  @Query(() => Product)
  async product(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.productService.findById(user.tenantId!, id);
  }

  @Query(() => Product)
  async productByBarcode(
    @CurrentUser() user: AuthenticatedUser,
    @Args('barcode') barcode: string,
  ) {
    return this.productService.findByBarcode(user.tenantId!, barcode);
  }

  @Mutation(() => Product)
  async createProduct(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateProductInput,
  ) {
    return this.productService.create(user.tenantId!, input);
  }

  @Mutation(() => Product)
  async updateProduct(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateProductInput,
  ) {
    return this.productService.update(user.tenantId!, id, input);
  }

  @Mutation(() => Boolean)
  async deleteProduct(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.productService.remove(user.tenantId!, id);
  }

  // ---- Variants ----

  @Query(() => [ProductVariant])
  async productVariants(
    @CurrentUser() user: AuthenticatedUser,
    @Args('productId', { type: () => ID }) productId: string,
  ) {
    return this.productService.findVariantsByProduct(
      user.tenantId!,
      productId,
    );
  }

  @Mutation(() => ProductVariant)
  async createVariant(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateVariantInput,
  ) {
    return this.productService.createVariant(user.tenantId!, input);
  }

  @Mutation(() => ProductVariant)
  async updateVariant(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateVariantInput,
  ) {
    return this.productService.updateVariant(user.tenantId!, id, input);
  }

  @Mutation(() => Boolean)
  async deleteVariant(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.productService.removeVariant(user.tenantId!, id);
  }

  // ---- Units ----

  @Query(() => [ProductUnit])
  async productUnits(
    @CurrentUser() user: AuthenticatedUser,
    @Args('productId', { type: () => ID }) productId: string,
  ) {
    return this.productService.findUnitsByProduct(user.tenantId!, productId);
  }

  @Mutation(() => ProductUnit)
  async createUnit(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateUnitInput,
  ) {
    return this.productService.createUnit(user.tenantId!, input);
  }

  @Mutation(() => ProductUnit)
  async updateUnit(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateUnitInput,
  ) {
    return this.productService.updateUnit(user.tenantId!, id, input);
  }

  @Mutation(() => Boolean)
  async deleteUnit(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.productService.removeUnit(user.tenantId!, id);
  }
}
