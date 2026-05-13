import { createFileRoute } from '@tanstack/react-router'
import { UnitsPage } from '@/app/units'

export const Route = createFileRoute('/_layout/units/')({
  component: UnitsPage,
})
