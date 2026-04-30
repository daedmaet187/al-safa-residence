-- AlterTable: add firstName/lastName, make phone required+unique, make passwordHash nullable, make email optional

-- 1. Add new columns
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "firstName" TEXT NOT NULL DEFAULT '';
ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "lastName"  TEXT NOT NULL DEFAULT '';

-- 2. Populate firstName/lastName from existing name field
UPDATE "users" SET
  "firstName" = SPLIT_PART("name", ' ', 1),
  "lastName"  = CASE
    WHEN POSITION(' ' IN "name") > 0
    THEN SUBSTRING("name" FROM POSITION(' ' IN "name") + 1)
    ELSE ''
  END;

-- 3. Fill missing phone values with a placeholder so we can add NOT NULL
UPDATE "users" SET "phone" = 'UNSET-' || "id" WHERE "phone" IS NULL OR "phone" = '';

-- 3b. Assign real phone numbers to known demo accounts before adding unique constraint
UPDATE "users" SET "phone" = '+9640000000001', "firstName" = 'Al-Safa', "lastName" = 'Admin'
  WHERE "email" = 'admin@alsafa.local';
UPDATE "users" SET "phone" = '+9647501234567', "firstName" = 'Ahmad', "lastName" = 'Al-Safa'
  WHERE "email" = 'resident@alsafa.local';
UPDATE "users" SET "phone" = '+9647502345678', "firstName" = 'Fatima', "lastName" = 'Al-Zahra'
  WHERE "email" = 'fatima@alsafa.local';
UPDATE "users" SET "phone" = '+9647901112233', "firstName" = 'Khaled', "lastName" = 'Al-Amin'
  WHERE "email" = 'guard@alsafa.local';

-- 4. Make phone NOT NULL and add unique constraint
ALTER TABLE "users" ALTER COLUMN "phone" SET NOT NULL;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_phone_key') THEN
    ALTER TABLE "users" ADD CONSTRAINT "users_phone_key" UNIQUE ("phone");
  END IF;
END $$;

-- 5. Make passwordHash nullable (residents/security won't have one)
ALTER TABLE "users" ALTER COLUMN "passwordHash" DROP NOT NULL;

-- 6. Make email nullable (phone is now the primary identifier)
ALTER TABLE "users" ALTER COLUMN "email" DROP NOT NULL;
