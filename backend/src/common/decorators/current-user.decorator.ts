import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Custom parameter decorator that extracts the authenticated user
 * from the request object (populated by JwtStrategy.validate()).
 *
 * Usage: @CurrentUser() user: { id: string; role: Role; phone_number: string }
 */
export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
