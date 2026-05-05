import { IsString, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';
import { HouseholdAccess } from '@prisma/client';

export class CreateMemberDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  phone: string;

  @IsString()
  @IsNotEmpty()
  relationship: string;

  @IsEnum(HouseholdAccess)
  @IsOptional()
  accessLevel?: HouseholdAccess = HouseholdAccess.LIMITED;
}
