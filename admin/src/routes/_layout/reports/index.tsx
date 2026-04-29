import { createFileRoute } from '@tanstack/react-router'
import ReportsPage from '@/app/reports'

export const Route = createFileRoute('/_layout/reports/')({
  component: ReportsPage,
})
