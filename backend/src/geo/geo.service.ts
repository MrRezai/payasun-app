import { Injectable } from '@nestjs/common';
// Use require to import the commonjs package safely
const iranCity = require('iran-city');

@Injectable()
export class GeoService {
  getProvinces() {
    if (typeof iranCity.allProvinces === 'function') {
      return iranCity.allProvinces();
    }
    return [];
  }

  getCitiesOfProvince(provinceId: number) {
    if (typeof iranCity.citiesOfProvince === 'function') {
      return iranCity.citiesOfProvince(provinceId);
    }
    return [];
  }
}
