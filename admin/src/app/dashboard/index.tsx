import { useQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import {
  Users,
  Building2,
  Wrench,
  CreditCard,
  ShieldCheck,
  TrendingUp,
  ArrowRight,
  Activity,
} from 'lucide-react'
import { formatDate } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import type { DashboardStats } from '@/types'

function useStats() {
  return useQuery({
    queryKey: queryKeys.dashboard.stats(),
    queryFn: async () => {
      const { data } = await api.get<DashboardStats>('/admin/dashboard/stats')
      return data
    },
  })
}

const statCards = [
  {
    label: 'Total Residents',
    key: 'totalResidents' as const,
    icon: Users,
    color: 'text-[var(--primary)]',
    bg: 'bg-[var(--primary-light)]',
    href: '/residents',
  },
  {
    label: 'Total Units',
    key: 'totalUnits' as const,
    icon: Building2,
    color: 'text-[var(--secondary)]',
    bg: 'bg-blue-50',
    href: '/units',
  },
  {
    label: 'Pending Maintenance',
    key: 'pendingMaintenance' as const,
    icon: Wrench,
    color: 'text-[var(--warning)]',
    bg: 'bg-[var(--warning-light)]',
    href: '/maintenance',
  },
  {
    label: 'Overdue Bills',
    key: 'overdueBills' as const,
    icon: CreditCard,
    color: 'text-[var(--danger)]',
    bg: 'bg-[var(--danger-light)]',
    href: '/billing',
  },
  {
    label: 'Occupied Units',
    key: 'occupiedUnits' as const,
    icon: TrendingUp,
    color: 'text-[var(--success)]',
    bg: 'bg-[var(--success-light)]',
    href: '/units',
  },
  {
    label: 'Active Guest Passes',
    key: 'activeGuestPasses' as const,
    icon: ShieldCheck,
    color: 'text-[var(--gate-guest)]',
    bg: 'bg-blue-50',
    href: '/gate',
  },
]

const activityTypeColors: Record<string, 'success' | 'warning' | 'default' | 'accent' | 'danger'> = {
  maintenance: 'warning',
  payment: 'success',
  guest_pass: 'default',
  announcement: 'accent',
  resident: 'default',
}

export default function DashboardPage() {
  const { data: stats, isLoading } = useStats()

  return (
    <div className="space-y-6">
      {/* Page header */}
      <div>
        <h1 className="text-2xl font-bold text-[var(--text)]">Dashboard</h1>
        <p className="text-sm text-[var(--text-muted)] mt-1">
          Al-Safa Residence — overview for today
        </p>
      </div>

      {/* Stats grid */}
      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        {statCards.map((card) => (
          <Link key={card.key} to={card.href}>
            <Card className="hover:shadow-[var(--shadow-card-hover)] transition-shadow cursor-pointer">
              <CardContent className="p-5">
                <div className="flex items-start justify-between">
                  <div>
                    <p className="text-xs font-medium text-[var(--text-muted)] uppercase tracking-wider">
                      {card.label}
                    </p>
                    {isLoading ? (
                      <Skeleton className="h-8 w-16 mt-2" />
                    ) : (
                      <p className="text-3xl font-bold text-[var(--text)] mt-1">
                        {stats?.[card.key] ?? 0}
                      </p>
                    )}
                  </div>
                  <div className={`p-2.5 rounded-[var(--radius-md)] ${card.bg}`}>
                    <card.icon className={`h-5 w-5 ${card.color}`} />
                  </div>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      {/* Bottom section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Activity */}
        <Card>
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <Activity className="h-4 w-4 text-[var(--text-muted)]" />
                Recent Activity
              </CardTitle>
            </div>
          </CardHeader>
          <CardContent className="space-y-3">
            {isLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="flex items-start gap-3">
                  <Skeleton className="h-8 w-8 rounded-full shrink-0" />
                  <div className="flex-1 space-y-1">
                    <Skeleton className="h-3 w-3/4" />
                    <Skeleton className="h-3 w-1/3" />
                  </div>
                </div>
              ))
            ) : stats?.recentActivity?.length ? (
              stats.recentActivity.slice(0, 8).map((item) => (
                <div key={item.id} className="flex items-start gap-3">
                  <Badge variant={activityTypeColors[item.type] ?? 'default'} className="mt-0.5 shrink-0">
                    {item.type.replace('_', ' ')}
                  </Badge>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm text-[var(--text)] truncate">{item.message}</p>
                    <p className="text-xs text-[var(--text-muted)]">{formatDate(item.createdAt)}</p>
                  </div>
                </div>
              ))
            ) : (
              <p className="text-sm text-[var(--text-muted)] text-center py-4">No recent activity</p>
            )}
          </CardContent>
        </Card>

        {/* Quick Links */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {[
              { href: '/residents', label: 'Manage Residents', desc: 'View and edit resident profiles', icon: Users },
              { href: '/billing', label: 'Billing & Payments', desc: 'Review overdue bills', icon: CreditCard },
              { href: '/maintenance', label: 'Maintenance Requests', desc: 'Process pending requests', icon: Wrench },
              { href: '/gate', label: 'Gate & Security', desc: 'Monitor guest passes', icon: ShieldCheck },
              { href: '/announcements', label: 'Announcements', desc: 'Post community updates', icon: Activity },
              { href: '/reports', label: 'Reports', desc: 'View analytics & export data', icon: TrendingUp },
            ].map((link) => (
              <Link key={link.href} to={link.href}>
                <div className="flex items-center gap-3 p-3 rounded-[var(--radius-md)] hover:bg-[var(--bg)] transition-colors group">
                  <div className="p-2 rounded-[var(--radius-sm)] bg-[var(--primary-light)]">
                    <link.icon className="h-4 w-4 text-[var(--primary)]" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-[var(--text)]">{link.label}</p>
                    <p className="text-xs text-[var(--text-muted)]">{link.desc}</p>
                  </div>
                  <ArrowRight className="h-4 w-4 text-[var(--text-subtle)] group-hover:text-[var(--text-muted)] transition-colors" />
                </div>
              </Link>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
