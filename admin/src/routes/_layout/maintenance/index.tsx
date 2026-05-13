import { createFileRoute } from '@tanstack/react-router'
import { MaintenancePage } from '@/app/maintenance'

export const Route = createFileRoute('/_layout/maintenance/')({
  component: MaintenancePage,
})
