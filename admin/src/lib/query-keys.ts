export const queryKeys = {
  dashboard: {
    all: ['dashboard'] as const,
    stats: () => ['dashboard', 'stats'] as const,
    activity: () => ['dashboard', 'activity'] as const,
  },
  residents: {
    all: ['residents'] as const,
    list: (params?: Record<string, unknown>) => ['residents', 'list', params] as const,
    detail: (id: string) => ['residents', 'detail', id] as const,
  },
  units: {
    all: ['units'] as const,
    list: (params?: Record<string, unknown>) => ['units', 'list', params] as const,
    detail: (id: string) => ['units', 'detail', id] as const,
  },
  billing: {
    all: ['billing'] as const,
    bills: (params?: Record<string, unknown>) => ['billing', 'bills', params] as const,
    payments: (params?: Record<string, unknown>) => ['billing', 'payments', params] as const,
    overdue: (params?: Record<string, unknown>) => ['billing', 'overdue', params] as const,
  },
  maintenance: {
    all: ['maintenance'] as const,
    list: (params?: Record<string, unknown>) => ['maintenance', 'list', params] as const,
    detail: (id: string) => ['maintenance', 'detail', id] as const,
  },
  gate: {
    all: ['gate'] as const,
    passes: (params?: Record<string, unknown>) => ['gate', 'passes', params] as const,
    logs: (params?: Record<string, unknown>) => ['gate', 'logs', params] as const,
  },
  announcements: {
    all: ['announcements'] as const,
    list: (params?: Record<string, unknown>) => ['announcements', 'list', params] as const,
    detail: (id: string) => ['announcements', 'detail', id] as const,
  },
  staff: {
    all: ['staff'] as const,
    list: (params?: Record<string, unknown>) => ['staff', 'list', params] as const,
    detail: (id: string) => ['staff', 'detail', id] as const,
  },
  householdMembers: {
    all: ['household-members'] as const,
    byUnit: (unitId: string) => ['household-members', 'unit', unitId] as const,
  },
  reports: {
    all: ['reports'] as const,
    maintenance: () => ['reports', 'maintenance'] as const,
    payments: () => ['reports', 'payments'] as const,
    occupancy: () => ['reports', 'occupancy'] as const,
    gate: () => ['reports', 'gate'] as const,
  },
  conversations: {
    all: ['conversations'] as const,
    list: (params?: Record<string, unknown>) => ['conversations', 'list', params] as const,
    detail: (id: string) => ['conversations', 'detail', id] as const,
  },
  amenities: {
    all: ['amenities'] as const,
    list: () => [...queryKeys.amenities.all, 'list'] as const,
    detail: (id: string) => [...queryKeys.amenities.all, id] as const,
  },
  amenityBookings: {
    all: ['amenity-bookings'] as const,
    list: () => [...queryKeys.amenityBookings.all, 'list'] as const,
  },
}
