import { Module } from '@nestjs/common';
import { CashBookService } from './cashbook.service';
import { CashBookController } from './cashbook.controller';

@Module({
  providers: [CashBookService],
  controllers: [CashBookController],
  exports: [CashBookService],
})
export class CashBookModule {}
