import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AdminGuard } from '../admin/guards/admin.guard';
import { ItemsService } from './items.service';
import { SupplyItem } from '../entities/item.entity';

@ApiTags('Items')
@Controller()
export class ItemsController {
  constructor(private readonly itemsService: ItemsService) {}

  @Get('items')
  @ApiOperation({ summary: 'دریافت لیست تمام اقلام استاندارد تعریف‌شده' })
  async getAll(): Promise<SupplyItem[]> {
    return this.itemsService.findAll();
  }

  @Get('tips')
  @ApiOperation({ summary: 'دریافت تنظیمات تیپ‌ها و راهنماهای فعال سامانه' })
  async getTips(): Promise<any> {
    return this.itemsService.getPublicTips();
  }

  @Put('admin/tips')
  @ApiBearerAuth('access-token')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'به‌روزرسانی و فعال/غیرفعالسازی تیپ‌های راهنما' })
  async updateTips(@Body() body: any): Promise<any> {
    return this.itemsService.updateTips(body);
  }

  @Get('admin/items')
  @ApiBearerAuth('access-token')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'دریافت لیست اقلام برای پنل ادمین' })
  async getAdminItems(): Promise<SupplyItem[]> {
    return this.itemsService.findAll();
  }

  @Post('admin/items')
  @ApiBearerAuth('access-token')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'ایجاد قلم جدید' })
  async create(
    @Body('title') title: string,
    @Body('unit') unit: string,
  ): Promise<SupplyItem> {
    return this.itemsService.create(title, unit);
  }

  @Put('admin/items/:id')
  @ApiBearerAuth('access-token')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'ویرایش قلم' })
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body('title') title: string,
    @Body('unit') unit: string,
  ): Promise<SupplyItem> {
    return this.itemsService.update(id, title, unit);
  }

  @Delete('admin/items/:id')
  @ApiBearerAuth('access-token')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'حذف قلم' })
  async remove(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.itemsService.remove(id);
  }
}
