import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { Bill, Payment, PaginatedResponse } from '@/types'
import type { CreateBillValues } from '../-schema'

export function useBillList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.billing.bills(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Bill>>('/admin/bills', { params })
      return data
    },
  })
}

export function usePaymentList(params?: Record<string, unknown>) {
  return useQuery({
    queryKey: queryKeys.billing.payments(params),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Payment>>('/admin/payments', { params })
      return data
    },
  })
}

export function useOverdueBills() {
  return useQuery({
    queryKey: queryKeys.billing.overdue(),
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<Bill>>('/admin/bills?status=overdue')
      return data
    },
  })
}

export function useCreateBill() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: CreateBillValues) => {
      const { data } = await api.post<Bill>('/admin/bills', payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.billing.all })
      toast.success('Bill created successfully')
    },
    onError: () => toast.error('Failed to create bill'),
  })
}

export function useMarkBillPaid() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (billId: string) => {
      const { data } = await api.patch(`/admin/bills/${billId}/mark-paid`)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.billing.all })
      toast.success('Bill marked as paid')
    },
    onError: () => toast.error('Failed to update bill'),
  })
}
