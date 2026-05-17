-- Add soft delete (deletedAt) to Unit, Bill, Payment, MaintenanceRequest
ALTER TABLE "units" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "bills" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "payments" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "maintenance_requests" ADD COLUMN "deletedAt" TIMESTAMP(3);
