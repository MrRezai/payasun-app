import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SupplyItem } from '../entities/item.entity';
import { AppSetting } from '../entities/app-setting.entity';

const DEFAULT_TIPS = {
  employer_enabled: true,
  employer_title: 'راهنمای برآورد دقیق جوشکاری',
  employer_text: 'با بارگذاری نقشه‌های باکیفیت و تعیین طول دقیق شاسی، مقادیر مصرفی الکترود و آهن‌آلات را دقیق‌تر دریافت کنید.',
  welder_enabled: true,
  welder_title: 'راهنمای افزایش دریافت پروژه',
  welder_text: 'با تکمیل دقیق تخصص‌ها، سوابق کاری و پروژه‌ها، پیشنهادهای قیمت شما شانس بیشتری برای انتخاب توسط کارفرمایان دارند.',
};

@Injectable()
export class ItemsService {
  constructor(
    @InjectRepository(SupplyItem)
    private readonly itemsRepository: Repository<SupplyItem>,
    @InjectRepository(AppSetting)
    private readonly settingRepository: Repository<AppSetting>,
  ) {}

  async getPublicTips(): Promise<any> {
    const setting = await this.settingRepository.findOne({ where: { key: 'app_tips' } });
    if (!setting) return DEFAULT_TIPS;
    try {
      return JSON.parse(setting.value);
    } catch {
      return DEFAULT_TIPS;
    }
  }

  async updateTips(data: any): Promise<any> {
    let setting = await this.settingRepository.findOne({ where: { key: 'app_tips' } });
    if (!setting) {
      setting = this.settingRepository.create({ key: 'app_tips', value: JSON.stringify(data) });
    } else {
      setting.value = JSON.stringify(data);
    }
    await this.settingRepository.save(setting);
    return data;
  }

  async findAll(): Promise<SupplyItem[]> {
    return this.itemsRepository.find({ order: { title: 'ASC' } });
  }

  async findOne(id: number): Promise<SupplyItem> {
    const item = await this.itemsRepository.findOne({ where: { id } });
    if (!item) {
      throw new NotFoundException('قلم مورد نظر یافت نشد.');
    }
    return item;
  }

  async create(title: string, unit: string): Promise<SupplyItem> {
    const item = this.itemsRepository.create({ title, unit });
    return this.itemsRepository.save(item);
  }

  async update(id: number, title: string, unit: string): Promise<SupplyItem> {
    const item = await this.findOne(id);
    item.title = title;
    item.unit = unit;
    return this.itemsRepository.save(item);
  }

  async remove(id: number): Promise<void> {
    const item = await this.findOne(id);
    await this.itemsRepository.remove(item);
  }
}
