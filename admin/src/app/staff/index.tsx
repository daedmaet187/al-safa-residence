import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import type { ColumnDef } from '@tanstack/react-table'
import { Plus, MoreHorizontal, UserX, UserCheck, ShieldCheck } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from '@/components/ui/dialog'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { DataTable } from '@/components/data-table'
import { formatDate, getInitials } from '@/lib/utils'
import type { StaffMember } from '@/types'
import { useStaffList, useCreateStaff, useUpdateStaff } from './-components/service'

const createStaffSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  role: z.enum(['admin', 'security']),
  password: z.string().min(8),
})
type CreateStaffValues = z.infer<typeof createStaffSchema>

function CreateStaffDialog() {
  const [open, setOpen] = useState(false)
  const { mutate, isPending } = useCreateStaff()
  const form = useForm<CreateStaffValues>({
    resolver: zodResolver(createStaffSchema),
    defaultValues: { name: '', email: '', role: 'security', password: '' },
  })

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button><Plus className="h-4 w-4" /> Add Staff</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader><DialogTitle>Add Staff Member</DialogTitle></DialogHeader>
        <Form {...form}>
          <form
            onSubmit={form.handleSubmit((v) => mutate(v, { onSuccess: () => { setOpen(false); form.reset() } }))}
            className="space-y-4"
          >
            <div className="grid grid-cols-2 gap-4">
              <FormField control={form.control} name="name" render={({ field }) => (
                <FormItem className="col-span-2">
                  <FormLabel>Full Name</FormLabel>
                  <FormControl><Input placeholder="Ahmad Al-Hassan" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
              <FormField control={form.control} name="email" render={({ field }) => (
                <FormItem>
                  <FormLabel>Email</FormLabel>
                  <FormControl><Input type="email" placeholder="a@alsafa.com" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
              <FormField control={form.control} name="role" render={({ field }) => (
                <FormItem>
                  <FormLabel>Role</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl><SelectTrigger><SelectValue /></SelectTrigger></FormControl>
                    <SelectContent>
                      <SelectItem value="admin">Admin</SelectItem>
                      <SelectItem value="security">Security</SelectItem>
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )} />
              <FormField control={form.control} name="password" render={({ field }) => (
                <FormItem className="col-span-2">
                  <FormLabel>Password</FormLabel>
                  <FormControl><Input type="password" placeholder="••••••••" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={isPending}>{isPending ? 'Creating...' : 'Create'}</Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}

function ActionsCell({ member }: { member: StaffMember }) {
  const { mutate: update } = useUpdateStaff(member.id)
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
        <DropdownMenuItem onClick={() => update({ role: member.role === 'admin' ? 'security' : 'admin' })}>
          <ShieldCheck className="h-4 w-4" />
          Switch to {member.role === 'admin' ? 'Security' : 'Admin'}
        </DropdownMenuItem>
        {member.status === 'active' ? (
          <DropdownMenuItem
            className="text-[var(--danger)]"
            onClick={() => update({ status: 'inactive' })}
          >
            <UserX className="h-4 w-4" /> Deactivate
          </DropdownMenuItem>
        ) : (
          <DropdownMenuItem onClick={() => update({ status: 'active' })}>
            <UserCheck className="h-4 w-4" /> Reactivate
          </DropdownMenuItem>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

const staffColumns: ColumnDef<StaffMember>[] = [
  {
    id: 'avatar',
    header: '',
    cell: ({ row }) => (
      <div className="w-8 h-8 rounded-full bg-[var(--sidebar)] flex items-center justify-center text-white text-xs font-bold">
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
    accessorKey: 'role',
    header: 'Role',
    cell: ({ row }) => (
      <Badge variant={row.original.role === 'admin' ? 'default' : 'secondary'}>
        {row.original.role}
      </Badge>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={row.original.status === 'active' ? 'success' : 'secondary'}>
        {row.original.status}
      </Badge>
    ),
  },
  {
    accessorKey: 'createdAt',
    header: 'Added',
    cell: ({ row }) => <span className="text-sm text-[var(--text-muted)]">{formatDate(row.original.createdAt)}</span>,
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => <ActionsCell member={row.original} />,
    enableSorting: false,
  },
]

export default function StaffPage() {
  const { data, isLoading } = useStaffList()
  const staff = data?.data ?? []

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text)]">Staff</h1>
          <p className="text-sm text-[var(--text-muted)] mt-0.5">{data?.total ?? 0} staff members</p>
        </div>
        <CreateStaffDialog />
      </div>
      <DataTable
        columns={staffColumns}
        data={staff}
        searchPlaceholder="Search staff by name or email..."
        isLoading={isLoading}
      />
    </div>
  )
}
