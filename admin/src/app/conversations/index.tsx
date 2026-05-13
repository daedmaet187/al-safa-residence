import { useState } from 'react'
import type { ColumnDef } from '@tanstack/react-table'
import { MessageSquare } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { DataTable } from '@/components/data-table'
import { formatDate } from '@/lib/utils'
import type { Conversation } from '@/types'
import { useConversationList } from './-components/service'
import { ConversationDetail } from './-components/conversation-detail'

const statusVariant: Record<string, any> = {
  open: 'success',
  closed: 'secondary',
}

function ActionsCell({ conversation }: { conversation: Conversation }) {
  const [open, setOpen] = useState(false)
  return (
    <>
      <Button variant="ghost" size="sm" onClick={() => setOpen(true)}>
        <MessageSquare className="h-4 w-4 mr-1" />
        Open
      </Button>
      {open && (
        <ConversationDetail
          conversationId={conversation.id}
          open={open}
          onClose={() => setOpen(false)}
        />
      )}
    </>
  )
}

const columns: ColumnDef<Conversation>[] = [
  {
    id: 'resident',
    header: 'Resident',
    cell: ({ row }) => (
      <div>
        <p className="font-medium text-[var(--text)]">{row.original.resident?.name ?? '—'}</p>
        <p className="text-xs text-[var(--text-muted)]">{row.original.resident?.phone ?? '—'}</p>
      </div>
    ),
  },
  {
    id: 'unit',
    header: 'Unit',
    cell: ({ row }) => row.original.unit?.number ?? '—',
  },
  {
    accessorKey: 'subject',
    header: 'Subject',
    cell: ({ row }) => (
      <p className="max-w-xs truncate text-[var(--text)]">{row.original.subject ?? '—'}</p>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => (
      <Badge variant={statusVariant[row.original.status ?? 'open']}>
        {row.original.status ?? '—'}
      </Badge>
    ),
  },
  {
    id: 'lastMessage',
    header: 'Last Message',
    cell: ({ row }) => {
      const msgs = row.original.messages ?? []
      const last = msgs[msgs.length - 1]
      return last ? (
        <p className="text-sm text-[var(--text-muted)] max-w-xs truncate">{last.content}</p>
      ) : (
        <span className="text-[var(--text-muted)]">—</span>
      )
    },
  },
  {
    id: 'unread',
    header: 'Unread',
    cell: ({ row }) => {
      const count = row.original.unreadCount ?? 0
      return count > 0 ? (
        <Badge variant="warning">{count}</Badge>
      ) : (
        <span className="text-[var(--text-muted)]">—</span>
      )
    },
  },
  {
    accessorKey: 'updatedAt',
    header: 'Last Activity',
    cell: ({ row }) => (
      <span className="text-sm text-[var(--text-muted)]">
        {row.original.updatedAt ? formatDate(row.original.updatedAt) : '—'}
      </span>
    ),
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }) => <ActionsCell conversation={row.original} />,
    enableSorting: false,
  },
]

export function ConversationsPage() {
  const [statusFilter, setStatusFilter] = useState('all')

  const params = {
    ...(statusFilter !== 'all' && { status: statusFilter }),
  }

  const { data, isLoading } = useConversationList(params)
  const conversations = data?.data ?? []

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-[var(--text)]">Conversations</h1>
        <p className="text-sm text-[var(--text-muted)] mt-0.5">{data?.total ?? 0} total conversations</p>
      </div>

      <div className="flex gap-3">
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-36">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="open">Open</SelectItem>
            <SelectItem value="closed">Closed</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={conversations}
        searchPlaceholder="Search conversations…"
        isLoading={isLoading}
      />
    </div>
  )
}
