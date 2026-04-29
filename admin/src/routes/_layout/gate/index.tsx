import { createFileRoute } from '@tanstack/react-router'
import GatePage from '@/app/gate'

export const Route = createFileRoute('/_layout/gate/')({
  component: GatePage,
})
