import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { AmenityBooking, PaginatedResponse } from '@/types'

export function useAmenityBookingList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: [...queryKeys.amenityBookings.list(), params],
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<AmenityBooking>>(
        '/admin/amenities/bookings',
        { params: { take: 100, ...params } }
      )
      return {
        ...data,
        data: data.data.map((b) => ({
          ...b,
          status: b.status?.toLowerCase() as AmenityBooking['status'],
        })),
      }
    },
  })
}

export function useUpdateBookingStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      await api.patch(`/admin/amenities/bookings/${id}/status`, { status })
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.amenityBookings.all })
      queryClient.invalidateQueries({ queryKey: ['amenity-bookings', 'pending-count'] })
      toast.success('Booking updated')
    },
    onError: () => toast.error('Failed to update booking'),
  })
}
