import { useState } from 'react'
import type { ColumnDef } from '@tanstack/react-table'
import { MoreHorizontal, UserCheck, UserX, Pencil } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { formatDate, getInitials } from '@/lib/utils'
import type { Resident } from '@/types'
import { useDeactivateResident, useUpdateResident } from './service'

const statusVariant: Record<string, 'success' | 'warning' | 'danger' | 'secondary'> = {
  active: 'success',
  pending: 'warning',
  suspended: 'danger',
  inactive: 'secondary',
}

const editResidentSchema = z.object({
  name: z.string().min(2, 'Name is required'),
  phone: z.string().regex(/^\+?\d{10,15}$/, 'Enter a valid phone number (10–15 digits)'),
  status: z.enum(['active', 'inactive', 'suspended', 'pending']),
})
type EditResidentForm = z.infer<typeof editResidentSchema>

function EditResidentDialog({
  resident,
  onClose,
}: {
  resident: Resident
  onClose: () => void
}) {
  const { mutate, isPending } = useUpdateResident(resident.id)
  const form = useForm<EditResidentForm>({
    resolver: zodResolver(editResidentSchema),
    defaultValues: {
      name: resident.name ?? '',
      phone: resident.phone ?? '',
      status: (resident.status as EditResidentForm['status']) ?? 'active',
    },
  })

  return (
    <Dialog open onOpenChange={(open) => { if (!open) onClose() }}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Edit Resident</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form
            onSubmit={form.handleSubmit((v) =>
              mutate(v as any, { onSuccess: onClose })
            )}
            className="space-y-4"
          >
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Full Name</FormLabel>
                  <FormControl>
                    <Input placeholder="Ahmad Al-Safa" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="phone"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Phone</FormLabel>
                  <FormControl>
                    <Input placeholder="+9647700000000" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="status"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Status</FormLabel>
                  <Select onValueChange={field.onChange} value={field.value}>
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Select status" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      <SelectItem value="active">Active</SelectItem>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="suspended">Suspended</SelectItem>
                      <SelectItem value="inactive">Inactive</SelectItem>
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />
            <DialogFooter>
              <Button type="button" variant="outline" onClick={onClose}>
                Cancel
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? 'Saving...' : 'Save'}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}

function ActionsCell({ resident }: { resident: Resident }) {
  const { mutate: updateStatus } = useDeactivateResident()
  const [editing, setEditing] = useState(false)

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon" className="h-8 w-8">
            <MoreHorizontal className="h-4 w-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuLabel>Actions</DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuItem onClick={() => setEditing(true)}>
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
      {editing && (
        <EditResidentDialog resident={resident} onClose={() => setEditing(false)} />
      )}
    </>
  )
}

export const residentColumns: ColumnDef<Resident>[] = [
  {
    id: 'avatar',
    header: '',
    cell: ({ row }) => (
      <div className="w-8 h-8 rounded-full bg-[var(--primary-light)] flex items-center justify-center text-[var(--primary)] text-xs font-bold">
        {getInitials(row.original.name ?? '')}
      </div>
    ),
    enableSorting: false,
  },
  {
    accessorKey: 'name',
    header: 'Name',
    cell: ({ row }) => (
      <div>
        <p className="font-semibold text-[var(--text)]">{row.original.name ?? '—'}</p>
        <p className="text-xs text-[var(--text-muted)]">{row.original.email ?? ''}</p>
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
        {(row.original.units ?? []).length ? (
          (row.original.units ?? []).map((u) => (
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
      <span className="capitalize text-sm">{row.original.role ?? 'resident'}</span>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={statusVariant[row.original.status ?? 'inactive'] ?? 'secondary'}>
        {row.original.status ?? 'unknown'}
      </Badge>
    ),
  },
  {
    accessorKey: 'createdAt',
    header: 'Joined',
    cell: ({ row }) => (
      <span className="text-sm text-[var(--text-muted)]">{row.original.createdAt ? formatDate(row.original.createdAt) : '—'}</span>
    ),
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => <ActionsCell resident={row.original} />,
    enableSorting: false,
  },
]
