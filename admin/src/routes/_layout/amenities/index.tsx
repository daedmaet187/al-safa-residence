import { createFileRoute } from '@tanstack/react-router'
import AmenitiesPage from '@/app/amenities'

export const Route = createFileRoute('/_layout/amenities/')({
  component: AmenitiesPage,
})
