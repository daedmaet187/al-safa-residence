import { createFileRoute } from '@tanstack/react-router'
import AnnouncementsPage from '@/app/announcements'

export const Route = createFileRoute('/_layout/announcements/')({
  component: AnnouncementsPage,
})
