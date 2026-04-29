import { useQuery } from '@tanstack/react-query'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'

export interface MaintenanceReport {
  byCategory: Array<{ category: string; count: number }>
  byStatus: Array<{ status: string; count: number }>
  avgResolutionDays: number
}

export interface PaymentReport {
  collectedThisMonth: number
  overdueTotal: number
  byType: Array<{ type: string; amount: number; count: number }>
}

export interface OccupancyReport {
  total: number
  occupied: number
  vacant: number
  byType: Array<{ type: string; occupied: number; total: number }>
}

export interface GateReport {
  passesCreatedThisWeek: number
  scansPerDay: Array<{ date: string; approved: number; denied: number }>
}

export function useMaintenanceReport() {
  return useQuery({
    queryKey: queryKeys.reports.maintenance(),
    queryFn: async () => {
      const { data } = await api.get<MaintenanceReport>('/admin/reports/maintenance')
      return data
    },
  })
}

export function usePaymentReport() {
  return useQuery({
    queryKey: queryKeys.reports.payments(),
    queryFn: async () => {
      const { data } = await api.get<PaymentReport>('/admin/reports/payments')
      return data
    },
  })
}

export function useOccupancyReport() {
  return useQuery({
    queryKey: queryKeys.reports.occupancy(),
    queryFn: async () => {
      const { data } = await api.get<OccupancyReport>('/admin/reports/occupancy')
      return data
    },
  })
}

export function useGateReport() {
  return useQuery({
    queryKey: queryKeys.reports.gate(),
    queryFn: async () => {
      const { data } = await api.get<GateReport>('/admin/reports/gate')
      return data
    },
  })
}
