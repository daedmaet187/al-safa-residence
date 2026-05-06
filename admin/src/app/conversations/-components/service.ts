import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { Conversation, Message, PaginatedResponse } from '@/types'

export function useConversationList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.conversations.list(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Conversation>>('/admin/conversations', { params })
      return data
    },
  })
}

export function useConversationDetail(id: string) {
  return useQuery({
    queryKey: queryKeys.conversations.detail(id),
    queryFn: async () => {
      const { data } = await api.get<Conversation>(`/admin/conversations/${id}`)
      return data
    },
    enabled: !!id,
  })
}

export function useAdminSendMessage() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, content }: { id: string; content: string }) => {
      const { data } = await api.post<Message>(`/admin/conversations/${id}/messages`, { content })
      return data
    },
    onSuccess: (_, { id }) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.conversations.detail(id) })
      queryClient.invalidateQueries({ queryKey: queryKeys.conversations.all })
    },
    onError: () => toast.error('Failed to send message'),
  })
}

export function useUpdateConversationStatus() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async ({ id, status }: { id: string; status: string }) => {
      const { data } = await api.patch(`/admin/conversations/${id}/status`, { status })
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.conversations.all })
      toast.success('Conversation updated')
    },
    onError: () => toast.error('Failed to update conversation'),
  })
}

export function useMarkConversationRead() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (id: string) => {
      const { data } = await api.patch(`/admin/conversations/${id}/read`)
      return data
    },
    onSuccess: (_, id) => {
      queryClient.invalidateQueries({ queryKey: queryKeys.conversations.detail(id) })
      queryClient.invalidateQueries({ queryKey: queryKeys.conversations.all })
    },
  })
}
