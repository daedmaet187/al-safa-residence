import { createFileRoute, Outlet, redirect } from '@tanstack/react-router'
import { Sidebar } from '@/components/common/sidebar'
import { DarkModeToggle } from '@/components/common/dark-mode-toggle'
import { Bell } from 'lucide-react'
import { Button } from '@/components/ui/button'

export const Route = createFileRoute('/_layout')({
  beforeLoad: () => {
    const token = localStorage.getItem('alsafa_admin_token')
    if (!token) {
      throw redirect({ to: '/login' })
    }
  },
  component: DashboardLayout,
})

function DashboardLayout() {
  return (
    <div className="min-h-screen bg-[var(--bg)]">
      <Sidebar />
      <div className="pl-60">
        {/* Top bar */}
        <header className="sticky top-0 z-30 h-14 flex items-center gap-4 bg-[var(--surface)] border-b border-[var(--border)] px-6">
          <div className="flex-1" />
          <Button variant="ghost" size="icon">
            <Bell className="h-4 w-4" />
          </Button>
          <DarkModeToggle />
        </header>
        {/* Main content */}
        <main className="p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
