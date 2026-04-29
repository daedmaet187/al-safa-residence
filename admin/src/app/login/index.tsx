import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useMutation } from '@tanstack/react-query'
import { useNavigate } from '@tanstack/react-router'
import { toast } from 'sonner'
import { Building2, Lock, Mail } from 'lucide-react'
import api, { setToken } from '@/lib/axios'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
})
type LoginValues = z.infer<typeof loginSchema>

export default function LoginPage() {
  const navigate = useNavigate()

  const form = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: '', password: '' },
  })

  const { mutate, isPending } = useMutation({
    mutationFn: async (values: LoginValues) => {
      const { data } = await api.post('/auth/admin/login', values)
      return data
    },
    onSuccess: (data) => {
      setToken(data.accessToken)
      navigate({ to: '/' })
    },
    onError: () => {
      toast.error('Invalid credentials. Please try again.')
    },
  })

  return (
    <div className="min-h-screen bg-[var(--bg)] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-[var(--radius-xl)] bg-[var(--primary)] mb-4">
            <Building2 className="h-7 w-7 text-white" />
          </div>
          <h1 className="text-2xl font-bold text-[var(--text)]">
            Al-Safa <span className="gold-gradient-text">Admin</span>
          </h1>
          <p className="text-sm text-[var(--text-muted)] mt-1">Sign in to the management portal</p>
        </div>

        {/* Card */}
        <div className="bg-[var(--surface)] rounded-[var(--radius-xl)] border border-[var(--border)] p-8 shadow-[var(--shadow-lg)]">
          <Form {...form}>
            <form onSubmit={form.handleSubmit((v) => mutate(v))} className="space-y-5">
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email address</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[var(--text-subtle)]" />
                        <Input
                          type="email"
                          placeholder="admin@alsafa.com"
                          className="pl-9"
                          {...field}
                        />
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Password</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-[var(--text-subtle)]" />
                        <Input type="password" placeholder="••••••••" className="pl-9" {...field} />
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type="submit" className="w-full" disabled={isPending}>
                {isPending ? 'Signing in...' : 'Sign in'}
              </Button>
            </form>
          </Form>
        </div>

        <p className="text-center text-xs text-[var(--text-subtle)] mt-6">
          Al-Safa Residence Management System &copy; 2025
        </p>
      </div>
    </div>
  )
}
