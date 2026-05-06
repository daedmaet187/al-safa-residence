CREATE TYPE "ConversationStatus" AS ENUM ('OPEN', 'CLOSED');
CREATE TYPE "SenderType" AS ENUM ('RESIDENT', 'ADMIN');

CREATE TABLE "conversations" (
  "id" TEXT NOT NULL,
  "residentId" TEXT NOT NULL,
  "unitId" TEXT,
  "subject" TEXT NOT NULL,
  "status" "ConversationStatus" NOT NULL DEFAULT 'OPEN',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "messages" (
  "id" TEXT NOT NULL,
  "conversationId" TEXT NOT NULL,
  "senderId" TEXT NOT NULL,
  "senderType" "SenderType" NOT NULL,
  "content" TEXT NOT NULL,
  "isRead" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "conversations" ADD CONSTRAINT "conversations_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_unitId_fkey" FOREIGN KEY ("unitId") REFERENCES "units"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversationId_fkey" FOREIGN KEY ("conversationId") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
