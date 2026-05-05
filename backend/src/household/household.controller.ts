import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  ForbiddenException,
  ValidationPipe,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { HouseholdService } from './household.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { User } from '../common/decorators/user.decorator';
import { CreateMemberDto } from './dto/create-member.dto';
import { UpdateMemberDto } from './dto/update-member.dto';

@ApiTags('household')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('household')
export class HouseholdController {
  constructor(private readonly householdService: HouseholdService) {}

  @Get('members')
  @ApiOperation({ summary: 'List household members for the authenticated resident' })
  getMembers(@User() user: any) {
    this.requirePrimaryResident(user);
    return this.householdService.getMembers(user.id);
  }

  @Post('members')
  @ApiOperation({ summary: 'Add a household member' })
  addMember(@User() user: any, @Body(ValidationPipe) dto: CreateMemberDto) {
    this.requirePrimaryResident(user);
    return this.householdService.addMember(user.id, dto);
  }

  @Patch('members/:id')
  @ApiOperation({ summary: 'Update household member name/relationship/accessLevel' })
  updateMember(
    @User() user: any,
    @Param('id') id: string,
    @Body(ValidationPipe) dto: UpdateMemberDto,
  ) {
    this.requirePrimaryResident(user);
    return this.householdService.updateMember(user.id, id, dto);
  }

  @Delete('members/:id')
  @ApiOperation({ summary: 'Remove household member (soft delete)' })
  removeMember(@User() user: any, @Param('id') id: string) {
    this.requirePrimaryResident(user);
    return this.householdService.removeMember(user.id, id);
  }

  private requirePrimaryResident(user: any) {
    if (user.actorType !== 'resident') {
      throw new ForbiddenException('Only the primary account holder can manage household members');
    }
  }
}
