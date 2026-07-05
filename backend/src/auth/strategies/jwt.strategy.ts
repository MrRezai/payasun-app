import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Role } from '../../common/enums/role.enum';

/**
 * The shape of the JWT payload after decoding.
 */
export interface JwtPayload {
  /** User UUID (subject claim) */
  sub: string;
  /** User role */
  role: Role;
  /** User phone number */
  phone_number: string;
  /** Issued-at timestamp (auto-added by jsonwebtoken) */
  iat?: number;
  /** Expiration timestamp (auto-added by jsonwebtoken) */
  exp?: number;
}

/**
 * The shape of the user object attached to the request after JWT validation.
 */
export interface AuthenticatedUser {
  id: string;
  role: Role;
  phone_number: string;
}

/**
 * Passport strategy that validates JWT Bearer tokens from the Authorization header.
 * On successful validation, attaches the user object to `request.user`.
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET'),
    });
  }

  /**
   * Called by Passport after the JWT is verified. The returned object
   * is attached to `request.user` and can be accessed via @CurrentUser().
   */
  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    return {
      id: payload.sub,
      role: payload.role,
      phone_number: payload.phone_number,
    };
  }
}
