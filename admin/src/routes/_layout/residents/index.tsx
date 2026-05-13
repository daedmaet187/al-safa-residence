import { createFileRoute } from '@tanstack/react-router'
import { ResidentsPage } from '@/app/residents'

export const Route = createFileRoute('/_layout/residents/')({
  component: ResidentsPage,
})
