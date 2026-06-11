// src/order/dto/confirm-order.dto.ts

import { IsOptional, IsNumber, IsString, Min } from 'class-validator';

export class ConfirmOrderDto {
  @IsOptional()
  @IsNumber({}, { message: 'paymentAmount phải là số' })
  @Min(0, { message: 'paymentAmount phải >= 0' })
  paymentAmount?: number;

  @IsOptional()
  @IsString({ message: 'paymentMethod phải là chuỗi' })
  paymentMethod?: string;

  @IsOptional()
  @IsString({ message: 'note phải là chuỗi' })
  note?: string;
}