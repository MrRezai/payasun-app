import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/**
 * Guard that enforces JWT Bearer authentication on protected routes.
 * Extends Passport's built-in 'jwt' strategy guard.
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
