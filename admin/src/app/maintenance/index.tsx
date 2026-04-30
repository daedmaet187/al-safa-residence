import { useState } from 'react'
import type { ColumnDef } from '@tanstack/react-table'
import { MoreHorizontal, ChevronRight } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { DataTable } from '@/components/data-table'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest } from '@/types'
import { useMaintenanceList, useUpdateMaintenanceStatus } from './-components/service'

const statusVariant: Record<string, any> = {
  pending: 'warning',
  in_progress: 'default',
  resolved: 'success',
  cancelled: 'secondary',
}

const priorityVariant: Record<string, any> = {
  low: 'secondary',
  medium: 'default',
  high: 'warning',
  urgent: 'danger',
}

function StatusUpdateDialog({ request, open, onClose }: { request: MaintenanceRequest; open: boolean; onClose: () => void }) {
  const [status, setStatus] = useState<MaintenanceRequest['status']>(request.status)
  const [notes, setNotes] = useState(request.adminNotes ?? '')
  const { mutate, isPending } = useUpdateMaintenanceStatus()

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Update: {request.title}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div>
            <p className="text-sm font-medium text-[var(--text)] mb-1">Description</p>
            <p className="text-sm text-[var(--text-muted)]">{request.description}</p>
          </div>
          <div>
            <p className="text-sm font-medium text-[var(--text)] mb-2">Update Status</p>
            <Select value={status} onValueChange={(v) => setStatus(v as MaintenanceRequest['status'])}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="in_progress">In Progress</SelectItem>
                <SelectItem value="resolved">Resolved</SelectItem>
                <SelectItem value="cancelled">Cancelled</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div>
            <p className="text-sm font-medium text-[var(--text)] mb-2">Admin Notes</p>
            <Textarea
              placeholder="Add a note for the resident..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={3}
            />
          </div>
          {(request.timeline ?? []).length > 0 && (
            <div>
              <p className="text-sm font-medium text-[var(--text)] mb-2">Timeline</p>
              <div className="space-y-2">
                {request.timeline.map((entry) => (
                  <div key={entry.id} className="flex gap-2 text-xs">
                    <span className="text-[var(--text-muted)]">{formatDate(entry.createdAt)}</span>
                    <Badge variant={statusVariant[entry.status]} className="text-xs">{entry.status}</Badge>
                    {entry.note && <span className="text-[var(--text-muted)]">{entry.note}</span>}
                  </div>
                ))}
              </div>
            </div>
          )}
          <div className="flex justify-end gap-2 pt-2">
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button
              disabled={isPending}
              onClick={() => mutate({ id: request.id, status, adminNotes: notes }, { onSuccess: onClose })}
            >
              {isPending ? 'Saving...' : 'Save'}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}

function ActionsCell({ request }: { request: MaintenanceRequest }) {
  const [dialogOpen, setDialogOpen] = useState(false)
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
          <DropdownMenuItem onClick={() => setDialogOpen(true)}>
            <ChevronRight className="h-4 w-4" /> View & Update
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
      <StatusUpdateDialog
        request={request}
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
      />
    </>
  )
}

const maintenanceColumns: ColumnDef<MaintenanceRequest>[] = [
  {
    accessorKey: 'title',
    header: 'Title',
    cell: ({ row }) => (
      <div>
        <p className="font-semibold text-[var(--text)]">{row.original.title}</p>
        <p className="text-xs text-[var(--text-muted)] capitalize">{row.original.category}</p>
      </div>
    ),
  },
  { id: 'resident', header: 'Resident', cell: ({ row }) => row.original.resident.name },
  { id: 'unit', header: 'Unit', cell: ({ row }) => row.original.unit.number },
  {
    accessorKey: 'priority',
    header: 'Priority',
    cell: ({ row }) => (
      <Badge variant={priorityVariant[row.original.priority]}>
        {row.original.priority}
      </Badge>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={statusVariant[row.original.status]}>
        {row.original.status.replace('_', ' ')}
      </Badge>
    ),
  },
  {
    accessorKey: 'submittedAt',
    header: 'Submitted',
    cell: ({ row }) => <span className="text-sm text-[var(--text-muted)]">{formatDate(row.original.submittedAt)}</span>,
  },
  { id: 'actions', header: '', cell: ({ row }) => <ActionsCell request={row.original} />, enableSorting: false },
]

export default function MaintenancePage() {
  const [statusFilter, setStatusFilter] = useState('all')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [priorityFilter, setPriorityFilter] = useState('all')

  const params = {
    ...(statusFilter !== 'all' && { status: statusFilter }),
    ...(categoryFilter !== 'all' && { category: categoryFilter }),
    ...(priorityFilter !== 'all' && { priority: priorityFilter }),
  }

  const { data, isLoading } = useMaintenanceList(params)
  const requests = data?.data ?? []

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-[var(--text)]">Maintenance</h1>
        <p className="text-sm text-[var(--text-muted)] mt-0.5">{data?.total ?? 0} total requests</p>
      </div>

      <div className="flex gap-3 flex-wrap">
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-36"><SelectValue placeholder="Status" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="pending">Pending</SelectItem>
            <SelectItem value="in_progress">In Progress</SelectItem>
            <SelectItem value="resolved">Resolved</SelectItem>
            <SelectItem value="cancelled">Cancelled</SelectItem>
          </SelectContent>
        </Select>
        <Select value={categoryFilter} onValueChange={setCategoryFilter}>
          <SelectTrigger className="w-40"><SelectValue placeholder="Category" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Categories</SelectItem>
            <SelectItem value="plumbing">Plumbing</SelectItem>
            <SelectItem value="electrical">Electrical</SelectItem>
            <SelectItem value="hvac">HVAC / AC</SelectItem>
            <SelectItem value="structural">Structural</SelectItem>
            <SelectItem value="cleaning">Cleaning</SelectItem>
            <SelectItem value="other">Other</SelectItem>
          </SelectContent>
        </Select>
        <Select value={priorityFilter} onValueChange={setPriorityFilter}>
          <SelectTrigger className="w-36"><SelectValue placeholder="Priority" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Priorities</SelectItem>
            <SelectItem value="urgent">Urgent</SelectItem>
            <SelectItem value="high">High</SelectItem>
            <SelectItem value="medium">Medium</SelectItem>
            <SelectItem value="low">Low</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={maintenanceColumns}
        data={requests}
        searchPlaceholder="Search maintenance requests..."
        isLoading={isLoading}
      />
    </div>
  )
}
