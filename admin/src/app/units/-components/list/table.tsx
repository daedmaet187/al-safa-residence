import type { ColumnDef } from '@tanstack/react-table'
import { Badge } from '@/components/ui/badge'
import type { Unit } from '@/types'

const statusVariant: Record<string, 'success' | 'warning' | 'danger'> = {
  occupied: 'success',
  vacant: 'secondary' as any,
  maintenance: 'warning',
}

export const unitColumns: ColumnDef<Unit>[] = [
  {
    accessorKey: 'number',
    header: 'Unit No.',
    cell: ({ row }) => (
      <span className="font-semibold text-[var(--text)]">{row.original.number}</span>
    ),
  },
  {
    accessorKey: 'building',
    header: 'Building',
    cell: ({ row }) => row.original.building ?? <span className="text-[var(--text-muted)]">—</span>,
  },
  {
    accessorKey: 'floor',
    header: 'Floor',
  },
  {
    accessorKey: 'type',
    header: 'Type',
    cell: ({ row }) => (
      <span className="capitalize">{row.original.type}</span>
    ),
  },
  {
    accessorKey: 'area',
    header: 'Area (m²)',
    cell: ({ row }) => `${row.original.area} m²`,
  },
  {
    id: 'residents',
    header: 'Resident(s)',
    cell: ({ row }) => (
      <div className="flex flex-col gap-0.5">
        {row.original.residents.length ? (
          row.original.residents.map((r) => (
            <span key={r.id} className="text-sm">{r.name}</span>
          ))
        ) : (
          <span className="text-xs text-[var(--text-muted)]">Vacant</span>
        )}
      </div>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={statusVariant[row.original.status]}>
        {row.original.status}
      </Badge>
    ),
  },
]
