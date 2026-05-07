import { Link, useLocation } from '@tanstack/react-router'
import { useQuery } from '@tanstack/react-query'
import {
  LayoutDashboard,
  Users,
  Building2,
  CreditCard,
  Wrench,
  ShieldCheck,
  Bell,
  UserCog,
  BarChart3,
  LogOut,
  MessageSquare,
  Calendar,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { clearToken } from '@/lib/axios'
import api from '@/lib/axios'
import { CurrencySelector } from './currency-selector'
import { DarkModeToggle } from './dark-mode-toggle'
import type { PaginatedResponse, AmenityBooking } from '@/types'

const navItems = [
  { href: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { href: '/residents', icon: Users, label: 'Residents' },
  { href: '/units', icon: Building2, label: 'Units' },
  { href: '/billing', icon: CreditCard, label: 'Billing' },
  { href: '/maintenance', icon: Wrench, label: 'Maintenance' },
  { href: '/gate', icon: ShieldCheck, label: 'Gate & Security' },
  { href: '/announcements', icon: Bell, label: 'Announcements' },
  { href: '/conversations', icon: MessageSquare, label: 'Conversations' },
  { href: '/staff', icon: UserCog, label: 'Staff' },
  { href: '/reports', icon: BarChart3, label: 'Reports' },
]

export function Sidebar() {
  const location = useLocation()

  const { data: pendingData } = useQuery({
    queryKey: ['amenity-bookings', 'pending-count'],
    queryFn: async () => {
      const { data } = await api.get<PaginatedResponse<AmenityBooking>>(
        '/admin/amenities/bookings',
        { params: { status: 'pending', take: 1 } }
      )
      return data.total
    },
    staleTime: 30_000,
  })
  const pendingCount = pendingData ?? 0

  const isAmenitiesActive = location.pathname.startsWith('/amenities')

  function handleLogout() {
    clearToken()
    window.location.href = '/login'
  }

  return (
    <aside className="fixed left-0 top-0 h-screen w-60 flex flex-col bg-[var(--sidebar)] z-40 select-none">
      {/* Logo */}
      <div className="px-6 py-5 border-b border-white/5">
        <div className="text-white font-bold text-lg tracking-tight">
          Al-Safa{' '}
          <span className="gold-gradient-text font-extrabold">Admin</span>
        </div>
        <div className="text-white/40 text-xs mt-0.5">Property Management</div>
        <div className="flex items-center gap-2 mt-3">
          <CurrencySelector />
          <DarkModeToggle />
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 overflow-y-auto space-y-0.5">
        {navItems.map((item) => {
          const active =
            item.href === '/'
              ? location.pathname === '/'
              : location.pathname.startsWith(item.href)
          return (
            <Link
              key={item.href}
              to={item.href}
              className={cn(
                'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                active
                  ? 'bg-[var(--primary)] text-white'
                  : 'text-white/60 hover:text-white hover:bg-white/5'
              )}
            >
              <item.icon className={cn('h-4 w-4 shrink-0', active ? 'text-white' : 'text-white/50')} />
              {item.label}
              {active && (
                <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[var(--accent)]" />
              )}
            </Link>
          )
        })}

        {/* Amenities section */}
        <div className="pt-1">
          <div className={cn(
            'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium',
            isAmenitiesActive ? 'text-white' : 'text-white/40'
          )}>
            <Calendar className="h-4 w-4 shrink-0 text-white/40" />
            Amenities
          </div>
          <div className="ml-3 space-y-0.5">
            <Link
              to="/amenities"
              className={cn(
                'flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                location.pathname === '/amenities'
                  ? 'bg-[var(--primary)] text-white'
                  : 'text-white/60 hover:text-white hover:bg-white/5'
              )}
            >
              Facilities
              {location.pathname === '/amenities' && (
                <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[var(--accent)]" />
              )}
            </Link>
            <Link
              to="/amenities/bookings"
              className={cn(
                'flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                location.pathname.startsWith('/amenities/bookings')
                  ? 'bg-[var(--primary)] text-white'
                  : 'text-white/60 hover:text-white hover:bg-white/5'
              )}
            >
              Bookings
              {pendingCount > 0 && (
                <span className="ml-auto bg-[var(--warning)] text-white text-xs font-bold rounded-full px-1.5 py-0.5 leading-none min-w-[1.25rem] text-center">
                  {pendingCount}
                </span>
              )}
              {pendingCount === 0 && location.pathname.startsWith('/amenities/bookings') && (
                <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[var(--accent)]" />
              )}
            </Link>
          </div>
        </div>
      </nav>

      {/* User footer */}
      <div className="px-3 py-4 border-t border-white/5">
        <div className="flex items-center gap-3 px-3 py-2 rounded-lg">
          <div className="w-8 h-8 rounded-full bg-[var(--primary)] flex items-center justify-center text-white text-xs font-bold shrink-0">
            SA
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-white text-xs font-semibold truncate">Admin User</div>
            <div className="text-white/40 text-xs truncate">Super Admin</div>
          </div>
          <button
            onClick={handleLogout}
            className="text-white/30 hover:text-white/70 transition-colors shrink-0"
            title="Sign out"
          >
            <LogOut className="h-4 w-4" />
          </button>
        </div>
      </div>
    </aside>
  )
}
