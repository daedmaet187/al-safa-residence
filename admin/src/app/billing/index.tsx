import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Plus, CheckCircle, AlertTriangle } from 'lucide-react'
import type { ColumnDef } from '@tanstack/react-table'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { DataTable } from '@/components/data-table'
import { formatDate, formatCurrency } from '@/lib/utils'
import type { Bill, Payment } from '@/types'
import { useBillList, usePaymentList, useOverdueBills, useCreateBill, useMarkBillPaid } from './-components/service'
import { createBillSchema, type CreateBillValues } from './-schema'

const billStatusVariant: Record<string, any> = {
  pending: 'warning',
  paid: 'success',
  overdue: 'danger',
  cancelled: 'secondary',
}

function CreateBillButton() {
  const [open, setOpen] = useState(false)
  const { mutate, isPending } = useCreateBill()
  const form = useForm<CreateBillValues>({
    resolver: zodResolver(createBillSchema),
    defaultValues: { residentId: '', unitId: '', type: 'MONTHLY_FEE', amount: 0, dueDate: '' },
  })

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button><Plus className="h-4 w-4" /> Create Bill</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader><DialogTitle>Create New Bill</DialogTitle></DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit((v) => mutate(v, { onSuccess: () => { setOpen(false); form.reset() } }))} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <FormField control={form.control} name="residentId" render={({ field }) => (
                <FormItem>
                  <FormLabel>Resident ID</FormLabel>
                  <FormControl><Input placeholder="resident-uuid" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
              <FormField control={form.control} name="unitId" render={({ field }) => (
                <FormItem>
                  <FormLabel>Unit ID</FormLabel>
                  <FormControl><Input placeholder="unit-uuid" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
              <FormField control={form.control} name="type" render={({ field }) => (
                <FormItem>
                  <FormLabel>Bill Type</FormLabel>
                  <Select onValueChange={field.onChange} defaultValue={field.value}>
                    <FormControl><SelectTrigger><SelectValue /></SelectTrigger></FormControl>
                    <SelectContent>
                      <SelectItem value="MONTHLY_FEE">Monthly Fee</SelectItem>
                      <SelectItem value="UTILITIES">Utilities</SelectItem>
                      <SelectItem value="MAINTENANCE_FEE">Maintenance Fee</SelectItem>
                      <SelectItem value="PARKING">Parking</SelectItem>
                      <SelectItem value="OTHER">Other</SelectItem>
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )} />
              <FormField control={form.control} name="amount" render={({ field }) => (
                <FormItem>
                  <FormLabel>Amount (IQD)</FormLabel>
                  <FormControl><Input type="number" placeholder="50000" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
              <FormField control={form.control} name="dueDate" render={({ field }) => (
                <FormItem className="col-span-2">
                  <FormLabel>Due Date</FormLabel>
                  <FormControl><Input type="date" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={isPending}>{isPending ? 'Creating...' : 'Create Bill'}</Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}

function BillsTab() {
  const { data, isLoading } = useBillList()
  const { mutate: markPaid } = useMarkBillPaid()
  const bills = data?.data ?? []

  const columns: ColumnDef<Bill>[] = [
    { id: 'resident', header: 'Resident', cell: ({ row }) => row.original.resident?.name ?? <span className="text-[var(--text-muted)]">—</span> },
    { id: 'unit', header: 'Unit', cell: ({ row }) => row.original.unit?.number ?? <span className="text-[var(--text-muted)]">—</span> },
    { accessorKey: 'type', header: 'Type', cell: ({ row }) => <span className="capitalize">{row.original.type.replace('_', ' ')}</span> },
    { accessorKey: 'amount', header: 'Amount', cell: ({ row }) => formatCurrency(row.original.amount) },
    { accessorKey: 'dueDate', header: 'Due Date', cell: ({ row }) => formatDate(row.original.dueDate) },
    { accessorKey: 'status', header: 'Status', cell: ({ row }) => <Badge variant={billStatusVariant[row.original.status]}>{row.original.status}</Badge> },
    {
      id: 'actions', header: '',
      cell: ({ row }) => row.original.status === 'pending' || row.original.status === 'overdue' ? (
        <Button variant="outline" size="sm" onClick={() => markPaid(row.original.id)}>
          <CheckCircle className="h-3.5 w-3.5" /> Mark Paid
        </Button>
      ) : null,
    },
  ]

  return <DataTable columns={columns} data={bills} searchPlaceholder="Search bills..." isLoading={isLoading} />
}

function PaymentsTab() {
  const { data, isLoading } = usePaymentList()
  const payments = data?.data ?? []

  const columns: ColumnDef<Payment>[] = [
    { id: 'resident', header: 'Resident', cell: ({ row }) => row.original.bill.resident.name },
    { id: 'unit', header: 'Unit', cell: ({ row }) => row.original.bill.unit.number },
    { id: 'type', header: 'Type', cell: ({ row }) => <span className="capitalize">{row.original.bill.type.replace('_', ' ')}</span> },
    { accessorKey: 'amount', header: 'Amount', cell: ({ row }) => formatCurrency(row.original.amount) },
    { accessorKey: 'method', header: 'Method', cell: ({ row }) => <span className="capitalize">{row.original.method}</span> },
    { accessorKey: 'paidAt', header: 'Paid At', cell: ({ row }) => formatDate(row.original.paidAt) },
  ]

  return <DataTable columns={columns} data={payments} searchPlaceholder="Search payments..." isLoading={isLoading} />
}

function OverdueTab() {
  const { data, isLoading } = useOverdueBills()
  const { mutate: markPaid } = useMarkBillPaid()
  const bills = data?.data ?? []

  return (
    <div className="space-y-3">
      {isLoading ? (
        <p className="text-[var(--text-muted)] text-sm">Loading...</p>
      ) : bills.length === 0 ? (
        <div className="flex flex-col items-center py-12 text-[var(--text-muted)]">
          <CheckCircle className="h-12 w-12 text-[var(--success)] mb-3 opacity-50" />
          <p className="font-medium">No overdue bills</p>
          <p className="text-sm">All bills are up to date</p>
        </div>
      ) : (
        bills.map((bill) => (
          <div key={bill.id} className="flex items-center gap-4 p-4 bg-[var(--danger-light)] border border-[var(--danger)]/20 rounded-[var(--radius-md)]">
            <AlertTriangle className="h-5 w-5 text-[var(--danger)] shrink-0" />
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-[var(--text)]">{bill.resident.name} — Unit {bill.unit.number}</p>
              <p className="text-sm text-[var(--text-muted)]">
                {bill.type.replace('_', ' ')} · {formatCurrency(bill.amount)} · Due {formatDate(bill.dueDate)}
              </p>
            </div>
            <Button size="sm" onClick={() => markPaid(bill.id)}>
              <CheckCircle className="h-3.5 w-3.5" /> Mark Paid
            </Button>
          </div>
        ))
      )}
    </div>
  )
}

export default function BillingPage() {
  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text)]">Billing & Payments</h1>
          <p className="text-sm text-[var(--text-muted)] mt-0.5">Manage bills, payments, and overdue accounts</p>
        </div>
        <CreateBillButton />
      </div>

      <Tabs defaultValue="bills">
        <TabsList>
          <TabsTrigger value="bills">Bills</TabsTrigger>
          <TabsTrigger value="payments">Payments</TabsTrigger>
          <TabsTrigger value="overdue">Overdue</TabsTrigger>
        </TabsList>
        <TabsContent value="bills"><BillsTab /></TabsContent>
        <TabsContent value="payments"><PaymentsTab /></TabsContent>
        <TabsContent value="overdue"><OverdueTab /></TabsContent>
      </Tabs>
    </div>
  )
}
