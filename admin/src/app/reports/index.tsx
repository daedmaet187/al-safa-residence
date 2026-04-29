import { Download, Wrench, CreditCard, Building2, ShieldCheck, TrendingUp, Clock } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { formatCurrency } from '@/lib/utils'
import {
  useMaintenanceReport,
  usePaymentReport,
  useOccupancyReport,
  useGateReport,
} from './-components/service'

function StatCard({ label, value, sub }: { label: string; value: string | number; sub?: string }) {
  return (
    <div className="text-center p-4 bg-[var(--bg)] rounded-[var(--radius-md)]">
      <p className="text-2xl font-bold text-[var(--text)]">{value}</p>
      <p className="text-xs font-medium text-[var(--text-muted)] mt-0.5">{label}</p>
      {sub && <p className="text-xs text-[var(--text-subtle)] mt-0.5">{sub}</p>}
    </div>
  )
}

function exportCSV(filename: string, rows: string[][]) {
  const csv = rows.map((row) => row.join(',')).join('\n')
  const blob = new Blob([csv], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${filename}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

function MaintenanceSection() {
  const { data, isLoading } = useMaintenanceReport()

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Wrench className="h-4 w-4 text-[var(--warning)]" />
            Maintenance
          </CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={() =>
              exportCSV('maintenance-report', [
                ['Category', 'Count'],
                ...(data?.byCategory.map((r) => [r.category, String(r.count)]) ?? []),
              ])
            }
          >
            <Download className="h-3.5 w-3.5" /> Export
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="grid grid-cols-3 gap-3">
            {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-20" />)}
          </div>
        ) : data ? (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-3">
              <StatCard label="Avg Resolution" value={`${data.avgResolutionDays ?? 0}d`} />
              <StatCard label="Total Open" value={data.byStatus.find((s) => s.status === 'pending')?.count ?? 0} />
              <StatCard label="Resolved" value={data.byStatus.find((s) => s.status === 'resolved')?.count ?? 0} />
            </div>
            <div>
              <p className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-2">By Category</p>
              <div className="space-y-1.5">
                {data.byCategory.map((item) => (
                  <div key={item.category} className="flex items-center justify-between">
                    <span className="text-sm capitalize">{item.category}</span>
                    <Badge variant="secondary">{item.count}</Badge>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <p className="text-sm text-[var(--text-muted)] text-center py-4">No data available</p>
        )}
      </CardContent>
    </Card>
  )
}

function PaymentSection() {
  const { data, isLoading } = usePaymentReport()

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <CreditCard className="h-4 w-4 text-[var(--success)]" />
            Payments
          </CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={() =>
              exportCSV('payment-report', [
                ['Type', 'Amount', 'Count'],
                ...(data?.byType.map((r) => [r.type, String(r.amount), String(r.count)]) ?? []),
              ])
            }
          >
            <Download className="h-3.5 w-3.5" /> Export
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="grid grid-cols-2 gap-3">
            {Array.from({ length: 2 }).map((_, i) => <Skeleton key={i} className="h-20" />)}
          </div>
        ) : data ? (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <StatCard label="Collected This Month" value={formatCurrency(data.collectedThisMonth)} />
              <StatCard label="Overdue Total" value={formatCurrency(data.overdueTotal)} />
            </div>
            <div>
              <p className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-2">By Type</p>
              <div className="space-y-1.5">
                {data.byType.map((item) => (
                  <div key={item.type} className="flex items-center justify-between">
                    <span className="text-sm capitalize">{item.type.replace('_', ' ')}</span>
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-[var(--text-muted)]">{item.count} bills</span>
                      <Badge variant="success">{formatCurrency(item.amount)}</Badge>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <p className="text-sm text-[var(--text-muted)] text-center py-4">No data available</p>
        )}
      </CardContent>
    </Card>
  )
}

function OccupancySection() {
  const { data, isLoading } = useOccupancyReport()
  const pct = data ? Math.round((data.occupied / data.total) * 100) : 0

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Building2 className="h-4 w-4 text-[var(--primary)]" />
            Occupancy
          </CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={() =>
              exportCSV('occupancy-report', [
                ['Type', 'Occupied', 'Total'],
                ...(data?.byType.map((r) => [r.type, String(r.occupied), String(r.total)]) ?? []),
              ])
            }
          >
            <Download className="h-3.5 w-3.5" /> Export
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="grid grid-cols-3 gap-3">
            {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-20" />)}
          </div>
        ) : data ? (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-3">
              <StatCard label="Total Units" value={data.total} />
              <StatCard label="Occupied" value={data.occupied} sub={`${pct}%`} />
              <StatCard label="Vacant" value={data.vacant} />
            </div>
            {/* Occupancy bar */}
            <div>
              <div className="flex justify-between text-xs text-[var(--text-muted)] mb-1.5">
                <span>Occupancy rate</span>
                <span className="font-semibold">{pct}%</span>
              </div>
              <div className="h-2.5 bg-[var(--bg)] rounded-full overflow-hidden">
                <div
                  className="h-full bg-[var(--primary)] rounded-full transition-all"
                  style={{ width: `${pct}%` }}
                />
              </div>
            </div>
            <div>
              <p className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-2">By Type</p>
              <div className="space-y-1.5">
                {data.byType.map((item) => (
                  <div key={item.type} className="flex items-center justify-between">
                    <span className="text-sm capitalize">{item.type}</span>
                    <span className="text-xs text-[var(--text-muted)]">{item.occupied}/{item.total} occupied</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <p className="text-sm text-[var(--text-muted)] text-center py-4">No data available</p>
        )}
      </CardContent>
    </Card>
  )
}

function GateSection() {
  const { data, isLoading } = useGateReport()

  return (
    <Card>
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <ShieldCheck className="h-4 w-4 text-[var(--gate-approved)]" />
            Gate Activity
          </CardTitle>
          <Button
            variant="outline"
            size="sm"
            onClick={() =>
              exportCSV('gate-report', [
                ['Date', 'Approved', 'Denied'],
                ...(data?.scansPerDay.map((r) => [r.date, String(r.approved), String(r.denied)]) ?? []),
              ])
            }
          >
            <Download className="h-3.5 w-3.5" /> Export
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-8" />)}
          </div>
        ) : data ? (
          <div className="space-y-4">
            <StatCard label="Passes Created This Week" value={data.passesCreatedThisWeek} />
            <div>
              <p className="text-xs font-semibold text-[var(--text-muted)] uppercase tracking-wider mb-2">Daily Scans</p>
              <div className="space-y-1.5">
                {data.scansPerDay.slice(0, 7).map((day) => (
                  <div key={day.date} className="flex items-center justify-between">
                    <span className="text-sm text-[var(--text-muted)]">{day.date}</span>
                    <div className="flex items-center gap-2">
                      <Badge variant="success">{day.approved} ✓</Badge>
                      {day.denied > 0 && <Badge variant="danger">{day.denied} ✗</Badge>}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <p className="text-sm text-[var(--text-muted)] text-center py-4">No data available</p>
        )}
      </CardContent>
    </Card>
  )
}

export default function ReportsPage() {
  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text)]">Reports & Analytics</h1>
          <p className="text-sm text-[var(--text-muted)] mt-0.5">Property performance overview</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <MaintenanceSection />
        <PaymentSection />
        <OccupancySection />
        <GateSection />
      </div>
    </div>
  )
}
