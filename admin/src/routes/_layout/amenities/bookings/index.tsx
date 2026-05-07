import { createFileRoute } from '@tanstack/react-router'
import AmenityBookingsPage from '@/app/amenities/bookings'

export const Route = createFileRoute('/_layout/amenities/bookings/')({
  component: AmenityBookingsPage,
})
