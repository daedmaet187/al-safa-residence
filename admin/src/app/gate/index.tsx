import type { ColumnDef } from '@tanstack/react-table'
import { ShieldCheck, ShieldX, Ban } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { DataTable } from '@/components/data-table'
import { formatDate } from '@/lib/utils'
import type { GuestPass, GateLog } from '@/types'
import { useGuestPasses, useGateLogs, useRevokeGuestPass } from './-components/service'

const passStatusVariant: Record<string, any> = {
  active: 'success',
  used: 'secondary',
  expired: 'secondary',
  revoked: 'danger',
}

const gateResultVariant: Record<string, any> = {
  approved: 'success',
  denied: 'danger',
}

function GuestPassesTab() {
  const { data, isLoading } = useGuestPasses({ status: 'active' })
  const { mutate: revoke } = useRevokeGuestPass()
  const passes = data?.data ?? []

  const columns: ColumnDef<GuestPass>[] = [
    {
      accessorKey: 'guestName',
      header: 'Guest Name',
      cell: ({ row }) => (
        <div>
          <p className="font-semibold text-[var(--text)]">{row.original.guestName}</p>
          {row.original.guestPhone && <p className="text-xs text-[var(--text-muted)]">{row.original.guestPhone}</p>}
        </div>
      ),
    },
    { id: 'resident', header: 'Resident', cell: ({ row }) => row.original.resident.name },
    { id: 'unit', header: 'Unit', cell: ({ row }) => row.original.unit.number },
    {
      accessorKey: 'status',
      header: 'Status',
      cell: ({ row }) => <Badge variant={passStatusVariant[row.original.status]}>{row.original.status}</Badge>,
    },
    {
      accessorKey: 'validUntil',
      header: 'Valid Until',
      cell: ({ row }) => <span className="text-sm">{formatDate(row.original.validUntil)}</span>,
    },
    {
      accessorKey: 'createdAt',
      header: 'Created',
      cell: ({ row }) => <span className="text-sm text-[var(--text-muted)]">{formatDate(row.original.createdAt)}</span>,
    },
    {
      id: 'actions',
      header: '',
      cell: ({ row }) =>
        row.original.status === 'active' ? (
          <Button
            variant="destructive"
            size="sm"
            onClick={() => revoke(row.original.id)}
          >
            <Ban className="h-3.5 w-3.5" /> Revoke
          </Button>
        ) : null,
      enableSorting: false,
    },
  ]

  return <DataTable columns={columns} data={passes} searchPlaceholder="Search by guest or resident..." isLoading={isLoading} />
}

function GateLogsTab() {
  const { data, isLoading } = useGateLogs()
  const logs = data?.data ?? []

  const columns: ColumnDef<GateLog>[] = [
    {
      accessorKey: 'guestName',
      header: 'Guest',
      cell: ({ row }) => <span className="font-medium">{row.original.guestName}</span>,
    },
    {
      id: 'unit',
      header: 'Unit',
      cell: ({ row }) => row.original.unit?.number ?? <span className="text-[var(--text-muted)]">—</span>,
    },
    {
      accessorKey: 'result',
      header: 'Result',
      cell: ({ row }) => (
        <div className="flex items-center gap-1.5">
          {row.original.result === 'approved' ? (
            <ShieldCheck className="h-4 w-4 text-[var(--success)]" />
          ) : (
            <ShieldX className="h-4 w-4 text-[var(--danger)]" />
          )}
          <Badge variant={gateResultVariant[row.original.result]}>{row.original.result}</Badge>
        </div>
      ),
    },
    {
      accessorKey: 'officer',
      header: 'Security Officer',
      cell: ({ row }) => row.original.officer ?? <span className="text-[var(--text-muted)]">—</span>,
    },
    {
      accessorKey: 'scannedAt',
      header: 'Scanned At',
      cell: ({ row }) => (
        <span className="text-sm text-[var(--text-muted)]">
          {formatDate(row.original.scannedAt, { dateStyle: 'medium', timeStyle: 'short' })}
        </span>
      ),
    },
  ]

  return <DataTable columns={columns} data={logs} searchPlaceholder="Search gate logs..." isLoading={isLoading} />
}

export default function GatePage() {
  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-bold text-[var(--text)]">Gate & Security</h1>
        <p className="text-sm text-[var(--text-muted)] mt-0.5">Guest passes and gate access logs</p>
      </div>

      <Tabs defaultValue="passes">
        <TabsList>
          <TabsTrigger value="passes">Active Passes</TabsTrigger>
          <TabsTrigger value="logs">Gate Log</TabsTrigger>
        </TabsList>
        <TabsContent value="passes"><GuestPassesTab /></TabsContent>
        <TabsContent value="logs"><GateLogsTab /></TabsContent>
      </Tabs>
    </div>
  )
}
