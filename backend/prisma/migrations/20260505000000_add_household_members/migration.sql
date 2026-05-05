-- CreateEnum
CREATE TYPE "HouseholdAccess" AS ENUM ('FULL', 'LIMITED');

-- AlterTable: add householdMemberId to guest_passes
ALTER TABLE "guest_passes" ADD COLUMN "householdMemberId" TEXT;

-- AlterTable: add householdMemberId to maintenance_requests
ALTER TABLE "maintenance_requests" ADD COLUMN "householdMemberId" TEXT;

-- CreateTable: household_members
CREATE TABLE "household_members" (
    "id" TEXT NOT NULL,
    "primaryUserId" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "relationship" TEXT NOT NULL,
    "accessLevel" "HouseholdAccess" NOT NULL DEFAULT 'LIMITED',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "household_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable: household_device_tokens
CREATE TABLE "household_device_tokens" (
    "id" TEXT NOT NULL,
    "householdMemberId" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "household_device_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "household_members_phone_key" ON "household_members"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "household_device_tokens_token_key" ON "household_device_tokens"("token");

-- AddForeignKey: household_members -> users
ALTER TABLE "household_members" ADD CONSTRAINT "household_members_primaryUserId_fkey"
    FOREIGN KEY ("primaryUserId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: household_device_tokens -> household_members
ALTER TABLE "household_device_tokens" ADD CONSTRAINT "household_device_tokens_householdMemberId_fkey"
    FOREIGN KEY ("householdMemberId") REFERENCES "household_members"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey: guest_passes -> household_members
ALTER TABLE "guest_passes" ADD CONSTRAINT "guest_passes_householdMemberId_fkey"
    FOREIGN KEY ("householdMemberId") REFERENCES "household_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey: maintenance_requests -> household_members
ALTER TABLE "maintenance_requests" ADD CONSTRAINT "maintenance_requests_householdMemberId_fkey"
    FOREIGN KEY ("householdMemberId") REFERENCES "household_members"("id") ON DELETE SET NULL ON UPDATE CASCADE;
