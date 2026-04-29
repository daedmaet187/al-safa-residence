import type { ColumnDef } from '@tanstack/react-table'
import { MoreHorizontal, UserCheck, UserX, Pencil } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { formatDate, getInitials } from '@/lib/utils'
import type { Resident } from '@/types'
import { useDeactivateResident } from './service'

const statusVariant: Record<string, 'success' | 'warning' | 'danger' | 'secondary'> = {
  active: 'success',
  pending: 'warning',
  suspended: 'danger',
  inactive: 'secondary',
}

function ActionsCell({ resident }: { resident: Resident }) {
  const { mutate: updateStatus } = useDeactivateResident()
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="h-8 w-8">
          <MoreHorizontal className="h-4 w-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuLabel>Actions</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem>
          <Pencil className="h-4 w-4" /> Edit
        </DropdownMenuItem>
        {resident.status === 'active' ? (
          <DropdownMenuItem
            className="text-[var(--danger)]"
            onClick={() => updateStatus({ id: resident.id, status: 'suspended' })}
          >
            <UserX className="h-4 w-4" /> Suspend
          </DropdownMenuItem>
        ) : (
          <DropdownMenuItem
            onClick={() => updateStatus({ id: resident.id, status: 'active' })}
          >
            <UserCheck className="h-4 w-4" /> Reactivate
          </DropdownMenuItem>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

export const residentColumns: ColumnDef<Resident>[] = [
  {
    id: 'avatar',
    header: '',
    cell: ({ row }) => (
      <div className="w-8 h-8 rounded-full bg-[var(--primary-light)] flex items-center justify-center text-[var(--primary)] text-xs font-bold">
        {getInitials(row.original.name)}
      </div>
    ),
    enableSorting: false,
  },
  {
    accessorKey: 'name',
    header: 'Name',
    cell: ({ row }) => (
      <div>
        <p className="font-semibold text-[var(--text)]">{row.original.name}</p>
        <p className="text-xs text-[var(--text-muted)]">{row.original.email}</p>
      </div>
    ),
  },
  {
    accessorKey: 'phone',
    header: 'Phone',
  },
  {
    id: 'units',
    header: 'Unit(s)',
    cell: ({ row }) => (
      <div className="flex flex-wrap gap-1">
        {row.original.units.length ? (
          row.original.units.map((u) => (
            <Badge key={u.id} variant="secondary" className="text-xs">
              {u.number}
            </Badge>
          ))
        ) : (
          <span className="text-xs text-[var(--text-muted)]">Unassigned</span>
        )}
      </div>
    ),
  },
  {
    accessorKey: 'role',
    header: 'Role',
    cell: ({ row }) => (
      <span className="capitalize text-sm">{row.original.role}</span>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={statusVariant[row.original.status] ?? 'secondary'}>
        {row.original.status}
      </Badge>
    ),
  },
  {
    accessorKey: 'createdAt',
    header: 'Joined',
    cell: ({ row }) => (
      <span className="text-sm text-[var(--text-muted)]">{formatDate(row.original.createdAt)}</span>
    ),
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => <ActionsCell resident={row.original} />,
    enableSorting: false,
  },
]
