import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { Amenity, PaginatedResponse } from '@/types'

export function useAmenityList() {
  return useQuery({
    queryKey: queryKeys.amenities.list(),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Amenity>>('/admin/amenities', {
        params: { take: 100 },
      })
      return data
    },
  })
}

export function useCreateAmenity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Partial<Amenity>) => {
      const { data } = await api.post<Amenity>('/admin/amenities', payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.amenities.all })
      toast.success('Amenity created successfully')
    },
    onError: () => toast.error('Failed to create amenity'),
  })
}

export function useUpdateAmenity(id: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Partial<Amenity>) => {
      const { data } = await api.patch<Amenity>(`/admin/amenities/${id}`, payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.amenities.all })
      toast.success('Amenity updated')
    },
    onError: () => toast.error('Failed to update amenity'),
  })
}

export function useDeactivateAmenity() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      await api.patch(`/admin/amenities/${id}/deactivate`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.amenities.all })
      toast.success('Amenity deactivated')
    },
    onError: () => toast.error('Failed to deactivate amenity'),
  })
}
