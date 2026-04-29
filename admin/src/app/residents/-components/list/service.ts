import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { Resident, PaginatedResponse } from '@/types'
import type { CreateResidentValues, UpdateResidentValues } from '../../-schema'

export function useResidentList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.residents.list(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Resident>>('/admin/residents', { params })
      return data
    },
  })
}

export function useCreateResident() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: CreateResidentValues) => {
      const { data } = await api.post<Resident>('/admin/residents', payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.residents.all })
      toast.success('Resident created successfully')
    },
    onError: () => toast.error('Failed to create resident'),
  })
}

export function useUpdateResident(id: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: UpdateResidentValues) => {
      const { data } = await api.patch<Resident>(`/admin/residents/${id}`, payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.residents.all })
      toast.success('Resident updated')
    },
    onError: () => toast.error('Failed to update resident'),
  })
}

export function useDeactivateResident() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: 'active' | 'suspended' }) => {
      const { data } = await api.patch(`/admin/residents/${id}`, { status })
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.residents.all })
      toast.success('Resident status updated')
    },
    onError: () => toast.error('Failed to update status'),
  })
}
