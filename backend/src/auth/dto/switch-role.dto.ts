import { ApiProperty } from '@nestjs/swagger';
import { IsEnum } from 'class-validator';
import { Role } from '../../common/enums/role.enum';

export class SwitchRoleDto {
  @ApiProperty({
    description: 'Target role to switch to',
    enum: Role,
    example: Role.WELDER,
  })
  @IsEnum(Role)
  role: Role;
}
