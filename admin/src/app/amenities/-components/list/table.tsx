import type { ColumnDef } from '@tanstack/react-table'
import { Badge } from '@/components/ui/badge'
import type { Amenity } from '@/types'

export const amenityColumns: ColumnDef<Amenity>[] = [
  {
    accessorKey: 'name',
    header: 'Name',
    cell: ({ row }) => (
      <span className="font-semibold text-[var(--text)]">{row.original.name}</span>
    ),
  },
  {
    accessorKey: 'location',
    header: 'Location',
    cell: ({ row }) =>
      row.original.location ?? <span className="text-[var(--text-muted)]">—</span>,
  },
  {
    accessorKey: 'capacity',
    header: 'Capacity',
    cell: ({ row }) => row.original.capacity,
  },
  {
    accessorKey: 'isActive',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={row.original.isActive ? 'success' : 'secondary'}>
        {row.original.isActive ? 'Active' : 'Inactive'}
      </Badge>
    ),
  },
]
