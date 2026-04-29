import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { Unit, PaginatedResponse } from '@/types'
import type { CreateUnitValues } from '../../-schema'

export function useUnitList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.units.list(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Unit>>('/admin/units', { params })
      return data
    },
  })
}

export function useCreateUnit() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: CreateUnitValues) => {
      const { data } = await api.post<Unit>('/admin/units', payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.units.all })
      toast.success('Unit created successfully')
    },
    onError: () => toast.error('Failed to create unit'),
  })
}

export function useUpdateUnit(id: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Partial<CreateUnitValues>) => {
      const { data } = await api.patch<Unit>(`/admin/units/${id}`, payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.units.all })
      toast.success('Unit updated')
    },
    onError: () => toast.error('Failed to update unit'),
  })
}
