import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { GuestPass, GateLog, PaginatedResponse } from '@/types'

export function useGuestPasses(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.gate.passes(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<GuestPass>>('/admin/gate/passes', { params })
      return data
    },
  })
}

export function useGateLogs(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.gate.logs(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<GateLog>>('/admin/gate/logs', { params })
      return data
    },
  })
}

export function useRevokeGuestPass() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (passId: string) => {
      const { data } = await api.patch(`/admin/gate/passes/${passId}/revoke`)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.gate.all })
      toast.success('Guest pass revoked')
    },
    onError: () => toast.error('Failed to revoke pass'),
  })
}
