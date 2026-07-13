import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';

@Injectable()
export class AdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('دسترسی غیرمجاز. توکن مدیریت یافت نشد.');
    }
    const token = authHeader.split(' ')[1];
    // Static admin token check matching the frontend
    if (token !== 'payasun_admin_secret_token_12345') {
      throw new UnauthorizedException('توکن مدیریت نامعتبر است.');
    }
    return true;
  }
}
