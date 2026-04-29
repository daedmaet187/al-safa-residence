import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const existing = await prisma.user.findUnique({
    where: { email: 'admin@alsafa.local' },
  });

  if (!existing) {
    const hash = await bcrypt.hash('AlSafaAdmin2026!', 12);
    await prisma.user.create({
      data: {
        email: 'admin@alsafa.local',
        name: 'Al-Safa Admin',
        passwordHash: hash,
        role: Role.ADMIN,
        isActive: true,
      },
    });
    console.log('Admin user created: admin@alsafa.local');
  } else {
    console.log('Admin user already exists, skipping.');
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
