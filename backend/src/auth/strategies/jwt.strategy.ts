import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service';

interface JwtPayload {
  sub: string;
  email: string;
  role: string;
  actorType?: string;
  accessLevel?: string;
  primaryUserId?: string;
  unitId?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('jwt.accessSecret'),
    });
  }

  async validate(payload: JwtPayload) {
    if (payload.actorType === 'household_member') {
      const member = await this.prisma.householdMember.findUnique({
        where: { id: payload.sub },
      });

      if (!member || !member.isActive) {
        throw new UnauthorizedException('Household member not found or inactive');
      }

      return {
        id: member.id,
        name: member.name,
        role: 'RESIDENT',
        actorType: 'household_member',
        accessLevel: member.accessLevel,
        primaryUserId: member.primaryUserId,
        unitId: payload.unitId,
      };
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });

    if (!user || !user.isActive || user.deletedAt) {
      throw new UnauthorizedException('User not found or inactive');
    }

    return {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      actorType: 'resident',
      accessLevel: 'FULL',
    };
  }
}
