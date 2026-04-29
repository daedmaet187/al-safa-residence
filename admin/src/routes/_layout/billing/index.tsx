import { createFileRoute } from '@tanstack/react-router'
import BillingPage from '@/app/billing'

export const Route = createFileRoute('/_layout/billing/')({
  component: BillingPage,
})
