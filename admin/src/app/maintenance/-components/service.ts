import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { MaintenanceRequest, PaginatedResponse } from '@/types'

export function useMaintenanceList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.maintenance.list(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<MaintenanceRequest>>('/admin/maintenance', { params })
      return data
    },
  })
}

export function useUpdateMaintenanceStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({
      id,
      status,
      adminNotes,
    }: {
      id: string
      status: MaintenanceRequest['status']
      adminNotes?: string
    }) => {
      const { data } = await api.patch(`/admin/maintenance/${id}`, { status, adminNotes })
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.maintenance.all })
      toast.success('Status updated')
    },
    onError: () => toast.error('Failed to update status'),
  })
}
