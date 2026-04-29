import { createFileRoute } from '@tanstack/react-router'
import StaffPage from '@/app/staff'

export const Route = createFileRoute('/_layout/staff/')({
  component: StaffPage,
})
