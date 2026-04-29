import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UsersController } from '../users/users.controller';
import { UsersService } from '../users/users.service';
import { RolesGuard } from '../common/guards/roles.guard';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

const mockUsersService = {
  findOne: jest.fn(),
  update: jest.fn(),
  findAll: jest.fn(),
  create: jest.fn(),
  remove: jest.fn(),
};

const mockReflector = {
  getAllAndOverride: jest.fn(),
};

const adminUser = { id: 'admin-1', role: 'ADMIN', email: 'admin@example.com' };
const residentUser = { id: 'resident-1', role: 'RESIDENT', email: 'r@example.com' };
const otherResidentId = 'resident-2';

describe('UsersController RBAC', () => {
  let controller: UsersController;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        { provide: UsersService, useValue: mockUsersService },
        { provide: Reflector, useValue: mockReflector },
      ],
    })
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({
        canActivate: (context: any) => {
          const requiredRoles = mockReflector.getAllAndOverride('roles', [
            context.getHandler(),
            context.getClass(),
          ]);
          if (!requiredRoles || requiredRoles.length === 0) return true;
          const { user } = context.switchToHttp().getRequest();
          const hasRole = requiredRoles.some((r: string) => user.role === r);
          if (!hasRole) throw new ForbiddenException('Insufficient permissions');
          return true;
        },
      })
      .compile();

    controller = module.get<UsersController>(UsersController);
  });

  describe('GET /users/:id', () => {
    const userRecord = {
      id: residentUser.id,
      email: residentUser.email,
      name: 'Resident',
      role: 'RESIDENT',
    };

    it('ADMIN can get any user by id', async () => {
      mockUsersService.findOne.mockResolvedValue(userRecord);

      const result = await controller.findOne(residentUser.id, adminUser);

      expect(mockUsersService.findOne).toHaveBeenCalledWith(residentUser.id);
      expect(result).toEqual(userRecord);
    });

    it('RESIDENT can get own record', async () => {
      mockUsersService.findOne.mockResolvedValue(userRecord);

      const result = await controller.findOne(residentUser.id, residentUser);

      expect(result).toEqual(userRecord);
    });

    it('RESIDENT cannot get another user record — throws ForbiddenException', async () => {
      await expect(
        controller.findOne(otherResidentId, residentUser),
      ).rejects.toThrow(ForbiddenException);

      expect(mockUsersService.findOne).not.toHaveBeenCalled();
    });
  });

  describe('PATCH /users/:id', () => {
    const updateDto = { name: 'Updated Name' };

    it('ADMIN can update any user', async () => {
      mockReflector.getAllAndOverride.mockReturnValue(['ADMIN']);
      mockUsersService.update.mockResolvedValue({ id: residentUser.id, ...updateDto });

      const result = await controller.update(residentUser.id, updateDto as any);

      expect(mockUsersService.update).toHaveBeenCalledWith(residentUser.id, updateDto);
      expect(result).toMatchObject(updateDto);
    });

    it('RolesGuard blocks RESIDENT from calling PATCH /users/:id', () => {
      mockReflector.getAllAndOverride.mockReturnValue(['ADMIN']);

      const fakeContext = {
        getHandler: () => controller.update,
        getClass: () => UsersController,
        switchToHttp: () => ({ getRequest: () => ({ user: residentUser }) }),
      };

      const guard = new RolesGuard(mockReflector as any);
      mockReflector.getAllAndOverride.mockReturnValue(['ADMIN']);

      expect(() => guard.canActivate(fakeContext as any)).toThrow(ForbiddenException);
    });
  });
});
