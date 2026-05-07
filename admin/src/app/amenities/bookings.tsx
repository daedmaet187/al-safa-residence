import { useState } from 'react'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { DataTable } from '@/components/data-table'
import { useAmenityBookingList, useUpdateBookingStatus } from './-components/bookings/service'
import type { AmenityBooking } from '@/types'
import type { ColumnDef } from '@tanstack/react-table'

const statusVariant: Record<string, 'warning' | 'success' | 'secondary'> = {
  pending: 'warning',
  confirmed: 'success',
  cancelled: 'secondary',
}

export default function AmenityBookingsPage() {
  const [statusFilter, setStatusFilter] = useState('all')

  const params = statusFilter !== 'all' ? { status: statusFilter } : {}
  const { data, isLoading } = useAmenityBookingList(params)
  const bookings = data?.data ?? []
  const { mutate: updateStatus } = useUpdateBookingStatus()

  const columns: ColumnDef<AmenityBooking>[] = [
    {
      id: 'resident',
      header: 'Resident',
      cell: ({ row }) => (
        <div>
          <div className="font-medium text-[var(--text)]">{row.original.resident?.name ?? '—'}</div>
          {row.original.resident?.phone && (
            <div className="text-xs text-[var(--text-muted)]">{row.original.resident.phone}</div>
          )}
        </div>
      ),
    },
    {
      id: 'unit',
      header: 'Unit',
      cell: ({ row }) => row.original.unit?.number ?? '—',
    },
    {
      id: 'amenity',
      header: 'Amenity',
      cell: ({ row }) => row.original.amenity?.name ?? '—',
    },
    {
      accessorKey: 'date',
      header: 'Date',
      cell: ({ row }) => row.original.date,
    },
    {
      id: 'time',
      header: 'Time',
      cell: ({ row }) => `${row.original.startTime} – ${row.original.endTime}`,
    },
    {
      accessorKey: 'status',
      header: 'Status',
      cell: ({ row }) => {
        const s = row.original.status?.toLowerCase() as string
        return (
          <Badge variant={statusVariant[s] ?? 'secondary'} className="capitalize">
            {s}
          </Badge>
        )
      },
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) => {
        const s = row.original.status?.toLowerCase()
        return (
          <div className="flex items-center gap-2">
            {s === 'pending' && (
              <Button
                variant="ghost"
                size="sm"
                className="text-[var(--success)] hover:text-[var(--success)]"
                onClick={() => updateStatus({ id: row.original.id, status: 'confirmed' })}
              >
                Confirm
              </Button>
            )}
            {(s === 'pending' || s === 'confirmed') && (
              <Button
                variant="ghost"
                size="sm"
                className="text-[var(--danger)] hover:text-[var(--danger)]"
                onClick={() => updateStatus({ id: row.original.id, status: 'cancelled' })}
              >
                Cancel
              </Button>
            )}
          </div>
        )
      },
    },
  ]

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text)]">Amenity Bookings</h1>
          <p className="text-sm text-[var(--text-muted)] mt-0.5">{data?.total ?? 0} total bookings</p>
        </div>
      </div>

      <div className="flex gap-3">
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-40">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            <SelectItem value="pending">Pending</SelectItem>
            <SelectItem value="confirmed">Confirmed</SelectItem>
            <SelectItem value="cancelled">Cancelled</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={bookings}
        searchPlaceholder="Search bookings..."
        isLoading={isLoading}
      />
    </div>
  )
}
