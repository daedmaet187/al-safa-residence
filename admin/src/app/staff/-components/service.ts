import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { StaffMember, PaginatedResponse } from '@/types'

export function useStaffList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.staff.list(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<StaffMember>>('/admin/staff', { params })
      return data
    },
  })
}

export function useCreateStaff() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { name: string; email: string; role: 'admin' | 'security'; password: string }) => {
      const { data } = await api.post<StaffMember>('/admin/staff', payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.staff.all })
      toast.success('Staff member created')
    },
    onError: () => toast.error('Failed to create staff member'),
  })
}

export function useUpdateStaff(id: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { role?: 'admin' | 'security'; status?: 'active' | 'inactive' }) => {
      const { data } = await api.patch<StaffMember>(`/admin/staff/${id}`, payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.staff.all })
      toast.success('Staff updated')
    },
    onError: () => toast.error('Failed to update staff'),
  })
}
