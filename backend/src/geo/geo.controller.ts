import { Controller, Get, Param, ParseIntPipe } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { GeoService } from './geo.service';

@ApiTags('Geo')
@Controller('geo')
export class GeoController {
  constructor(private readonly geoService: GeoService) {}

  @Get('provinces')
  @ApiOperation({ summary: 'Get list of all Iranian provinces' })
  @ApiResponse({ status: 200, description: 'Return list of provinces.' })
  getProvinces() {
    return this.geoService.getProvinces();
  }

  @Get('cities/:provinceId')
  @ApiOperation({ summary: 'Get list of cities inside a given province' })
  @ApiResponse({ status: 200, description: 'Return list of cities.' })
  getCities(@Param('provinceId', ParseIntPipe) provinceId: number) {
    return this.geoService.getCitiesOfProvince(provinceId);
  }
}
