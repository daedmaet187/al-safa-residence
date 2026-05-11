import { IsString, IsNotEmpty, IsEnum, IsOptional, Matches } from 'class-validator';
import { HouseholdAccess } from '@prisma/client';

export class CreateMemberDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^\+?\d{10,15}$/, { message: 'Phone must be 10–15 digits (e.g. 07501234567 or +9647501234567)' })
  phone: string;

  @IsString()
  @IsNotEmpty()
  relationship: string;

  @IsEnum(HouseholdAccess)
  @IsOptional()
  accessLevel?: HouseholdAccess = HouseholdAccess.LIMITED;
}
