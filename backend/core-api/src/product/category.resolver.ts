import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { CategoryService } from './category.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  Category,
  CreateCategoryInput,
  UpdateCategoryInput,
} from './dto/product.types';

@Resolver(() => Category)
export class CategoryResolver {
  constructor(private categoryService: CategoryService) {}

  @Query(() => [Category])
  async categories(@CurrentUser() user: AuthenticatedUser) {
    return this.categoryService.findAll(user.tenantId!);
  }

  @Query(() => Category)
  async category(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.categoryService.findById(user.tenantId!, id);
  }

  @Mutation(() => Category)
  async createCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateCategoryInput,
  ) {
    return this.categoryService.create(user.tenantId!, input);
  }

  @Mutation(() => Category)
  async updateCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateCategoryInput,
  ) {
    return this.categoryService.update(user.tenantId!, id, input);
  }

  @Mutation(() => Boolean)
  async deleteCategory(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.categoryService.remove(user.tenantId!, id);
  }
}
