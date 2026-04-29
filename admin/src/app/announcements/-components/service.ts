import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { Announcement, PaginatedResponse } from '@/types'

export function useAnnouncementList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.announcements.list(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Announcement>>('/admin/announcements', { params })
      return data
    },
  })
}

export function useCreateAnnouncement() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { title: string; body: string; isImportant: boolean; expiresAt?: string }) => {
      const { data } = await api.post<Announcement>('/admin/announcements', payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.announcements.all })
      toast.success('Announcement published')
    },
    onError: () => toast.error('Failed to publish announcement'),
  })
}

export function useUpdateAnnouncement(id: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: { title?: string; body?: string; isImportant?: boolean; expiresAt?: string }) => {
      const { data } = await api.patch<Announcement>(`/admin/announcements/${id}`, payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.announcements.all })
      toast.success('Announcement updated')
    },
    onError: () => toast.error('Failed to update announcement'),
  })
}

export function useDeleteAnnouncement() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/admin/announcements/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.announcements.all })
      toast.success('Announcement deleted')
    },
    onError: () => toast.error('Failed to delete announcement'),
  })
}
