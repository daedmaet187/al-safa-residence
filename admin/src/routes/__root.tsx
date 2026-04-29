import { createRootRoute, Outlet, redirect } from '@tanstack/react-router'
import { getToken } from '@/lib/axios'

export const Route = createRootRoute({
  beforeLoad: ({ location }) => {
    const token = getToken()
    const isLoginPage = location.pathname === '/login'

    if (!token && !isLoginPage) {
      throw redirect({ to: '/login' })
    }
    if (token && isLoginPage) {
      throw redirect({ to: '/' })
    }
  },
  component: () => <Outlet />,
})
