import { PrismaClient, RoleType, Language, ScheduleType, AnnouncementCategory, SandhaFrequency, PaymentMethod, PaymentStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('--- Seeding Database for Masjid Management & Namaz Time ---');

  // 1. Roles
  const roles = [
    { name: RoleType.SUPER_ADMIN, description: 'System-wide super administrator' },
    { name: RoleType.ADMIN, description: 'Masjid administrator with full masjid control' },
    { name: RoleType.FINANCE, description: 'Finance volunteer managing sandha and collections' },
    { name: RoleType.ANNOUNCEMENT, description: 'Volunteer managing broadcasts and announcements' },
  ];

  for (const role of roles) {
    await prisma.role.upsert({
      where: { name: role.name },
      update: { description: role.description },
      create: role,
    });
  }
  console.log('✓ Roles seeded');

  // 2. Super Admin User
  const superAdmin = await prisma.user.upsert({
    where: { phone: '+919876543210' },
    update: { isSuperAdmin: true },
    create: {
      phone: '+919876543210',
      name: 'Super Admin',
      language: Language.en,
      isSuperAdmin: true,
      isActive: true,
    },
  });
  console.log('✓ Super Admin created:', superAdmin.phone);

  // 3. Masjid Admins & Regular Users
  const adminUser1 = await prisma.user.upsert({
    where: { phone: '+919876543211' },
    update: {},
    create: {
      phone: '+919876543211',
      name: 'Moulana Ahmed (Chennai Admin)',
      language: Language.ta,
      isActive: true,
    },
  });

  const adminUser2 = await prisma.user.upsert({
    where: { phone: '+919876543212' },
    update: {},
    create: {
      phone: '+919876543212',
      name: 'Janab Ibrahim (Coimbatore Admin)',
      language: Language.ta,
      isActive: true,
    },
  });

  const regularUser = await prisma.user.upsert({
    where: { phone: '+919876543213' },
    update: {},
    create: {
      phone: '+919876543213',
      name: 'Abdul Rahman',
      language: Language.ta,
      isActive: true,
    },
  });
  console.log('✓ Sample users created');

  // 4. Masjids
  const masjid1 = await prisma.masjid.upsert({
    where: { qrToken: 'jamia-chennai-sample-token-12345' },
    update: {},
    create: {
      name: 'Jamia Masjid',
      nameTa: 'ஜாமியா பள்ளிவாசல்',
      address: '12 Anna Salai, Thousand Lights',
      city: 'Chennai',
      state: 'Tamil Nadu',
      country: 'India',
      latitude: 13.0604,
      longitude: 80.2496,
      phone: '+914428291234',
      qrToken: 'jamia-chennai-sample-token-12345',
      createdBy: adminUser1.id,
      isActive: true,
    },
  });

  const masjid2 = await prisma.masjid.upsert({
    where: { qrToken: 'madina-cbe-sample-token-67890' },
    update: {},
    create: {
      name: 'Madina Masjid',
      nameTa: 'மதீனா பள்ளிவாசல்',
      address: '45 Oppanakara Street',
      city: 'Coimbatore',
      state: 'Tamil Nadu',
      country: 'India',
      latitude: 11.0168,
      longitude: 76.9558,
      phone: '+914222305678',
      qrToken: 'madina-cbe-sample-token-67890',
      createdBy: adminUser2.id,
      isActive: true,
    },
  });
  console.log('✓ Masjids created: Jamia Masjid & Madina Masjid');

  // 5. Assign Masjid Admin Roles
  const adminRole = await prisma.role.findUniqueOrThrow({ where: { name: RoleType.ADMIN } });
  
  await prisma.masjidAdmin.upsert({
    where: {
      idx_masjid_admins_unique: {
        userId: adminUser1.id,
        masjidId: masjid1.id,
        roleId: adminRole.id,
      },
    },
    update: {},
    create: {
      userId: adminUser1.id,
      masjidId: masjid1.id,
      roleId: adminRole.id,
    },
  });

  await prisma.masjidAdmin.upsert({
    where: {
      idx_masjid_admins_unique: {
        userId: adminUser2.id,
        masjidId: masjid2.id,
        roleId: adminRole.id,
      },
    },
    update: {},
    create: {
      userId: adminUser2.id,
      masjidId: masjid2.id,
      roleId: adminRole.id,
    },
  });

  // 6. Memberships
  await prisma.membership.upsert({
    where: {
      idx_memberships_unique: {
        userId: regularUser.id,
        masjidId: masjid1.id,
      },
    },
    update: { isPrimary: true },
    create: {
      userId: regularUser.id,
      masjidId: masjid1.id,
      isPrimary: true,
    },
  });

  // 7. Today's Prayer Times
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  await prisma.prayerTime.upsert({
    where: {
      idx_prayer_times_unique: {
        masjidId: masjid1.id,
        date: today,
      },
    },
    update: {},
    create: {
      masjidId: masjid1.id,
      date: today,
      fajrAdhan: '05:00',
      fajrJamaah: '05:30',
      dhuhrAdhan: '12:30',
      dhuhrJamaah: '01:15',
      asrAdhan: '04:15',
      asrJamaah: '04:45',
      maghribAdhan: '06:15',
      maghribJamaah: '06:20',
      ishaAdhan: '07:45',
      ishaJamaah: '08:15',
      jummahKhutbah: '12:45',
      jummahJamaah: '01:30',
      updatedBy: adminUser1.id,
    },
  });

  // 8. Sample Sandha Plan & Enrollment
  const sandhaPlan = await prisma.sandhaPlan.create({
    data: {
      masjidId: masjid1.id,
      name: 'மாதாந்திர சந்தா / Monthly Maintenance Sandha',
      amount: 200.00,
      frequency: SandhaFrequency.MONTHLY,
      description: 'General maintenance and electricity expenses',
      createdBy: adminUser1.id,
    },
  });

  // Enroll Abdul Rahman (auto-linked)
  await prisma.sandhaPlanMember.create({
    data: {
      planId: sandhaPlan.id,
      userId: regularUser.id,
      phone: regularUser.phone,
      name: regularUser.name,
      autoLinked: true,
      linkedAt: new Date(),
    },
  });

  // 9. Sample Announcement
  await prisma.announcement.create({
    data: {
      masjidId: masjid1.id,
      createdBy: adminUser1.id,
      category: AnnouncementCategory.GENERAL,
      title: 'ஜும்ஆ தொழுகை நேரம் மாற்றம் / Jummah Time Update',
      titleTa: 'ஜும்ஆ தொழுகை நேரம் மாற்றம்',
      body: 'இந்த வாரம் முதல் ஜும்ஆ குத்பா மதியம் 12:45 மணிக்கு தொடங்கும்.',
      bodyTa: 'இந்த வாரம் முதல் ஜும்ஆ குத்பா மதியம் 12:45 மணிக்கு தொடங்கும்.',
      isPinned: true,
      publishedAt: new Date(),
    },
  });

  console.log('✓ Seed completed successfully!');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
