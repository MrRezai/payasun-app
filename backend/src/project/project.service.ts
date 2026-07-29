import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Project } from '../entities/project.entity';

export interface CreateProjectDto {
  title: string;
  description: string;
  city: string;
  province?: string;
  address?: string;
  image_urls?: string[];
}

export interface UpdateProjectDto {
  title?: string;
  description?: string;
  city?: string;
  province?: string;
  address?: string;
  image_urls?: string[];
}

@Injectable()
export class ProjectService {
  constructor(
    @InjectRepository(Project)
    private readonly projectRepository: Repository<Project>,
  ) {}

  async create(employerId: string, dto: CreateProjectDto): Promise<Project> {
    if (!dto.title || dto.title.trim().length === 0) {
      throw new BadRequestException('عنوان پروژه الزامی است.');
    }
    if (!dto.city || dto.city.trim().length === 0) {
      throw new BadRequestException('شهر محل پروژه الزامی است.');
    }

    const project = this.projectRepository.create({
      employerId,
      title: dto.title.trim(),
      description: dto.description ? dto.description.trim() : '',
      city: dto.city.trim(),
      province: dto.province ? dto.province.trim() : null,
      address: dto.address ? dto.address.trim() : null,
      image_urls: dto.image_urls ?? [],
    });

    return this.projectRepository.save(project);
  }

  async update(projectId: string, employerId: string, dto: UpdateProjectDto): Promise<Project> {
    const project = await this.projectRepository.findOne({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('پروژه مورد نظر یافت نشد.');
    }

    if (project.employerId !== employerId) {
      throw new ForbiddenException('شما دسترسی ویرایش این پروژه را ندارید.');
    }

    if (dto.title !== undefined) project.title = dto.title.trim();
    if (dto.description !== undefined) project.description = dto.description.trim();
    if (dto.city !== undefined) project.city = dto.city.trim();
    if (dto.province !== undefined) project.province = dto.province ? dto.province.trim() : null;
    if (dto.address !== undefined) project.address = dto.address ? dto.address.trim() : null;
    if (dto.image_urls !== undefined) project.image_urls = dto.image_urls;

    return this.projectRepository.save(project);
  }

  async remove(projectId: string, employerId: string): Promise<void> {
    const project = await this.projectRepository.findOne({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('پروژه مورد نظر یافت نشد.');
    }

    if (project.employerId !== employerId) {
      throw new ForbiddenException('شما دسترسی حذف این پروژه را ندارید.');
    }

    await this.projectRepository.remove(project);
  }

  async addImage(projectId: string, employerId: string, imageUrl: string): Promise<Project> {
    const project = await this.projectRepository.findOne({ where: { id: projectId } });

    if (!project) {
      throw new NotFoundException('پروژه مورد نظر یافت نشد.');
    }

    if (project.employerId !== employerId) {
      throw new ForbiddenException('شما دسترسی ویرایش این پروژه را ندارید.');
    }

    const currentImages = project.image_urls || [];
    if (currentImages.length >= 10) {
      throw new BadRequestException('حداکثر تعداد تصاویر مجاز برای هر پروژه ۱۰ عدد می‌باشد.');
    }

    project.image_urls = [...currentImages, imageUrl];
    return this.projectRepository.save(project);
  }

  async findByEmployer(employerId: string): Promise<Project[]> {
    return this.projectRepository.find({
      where: { employerId },
      relations: ['inquiries'],
      order: { created_at: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Project> {
    const project = await this.projectRepository.findOne({
      where: { id },
      relations: ['inquiries'],
    });

    if (!project) {
      throw new NotFoundException('پروژه مورد نظر یافت نشد.');
    }

    return project;
  }
}
