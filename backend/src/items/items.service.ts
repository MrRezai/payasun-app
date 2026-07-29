import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SupplyItem } from '../entities/item.entity';

@Injectable()
export class ItemsService {
  constructor(
    @InjectRepository(SupplyItem)
    private readonly itemsRepository: Repository<SupplyItem>,
  ) {}

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
