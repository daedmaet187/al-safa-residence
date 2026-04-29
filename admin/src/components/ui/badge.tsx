import * as React from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/utils'

const badgeVariants = cva(
  'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-[var(--primary-light)] text-[var(--primary)]',
        success: 'bg-[var(--success-light)] text-[var(--success)]',
        warning: 'bg-[var(--warning-light)] text-[var(--warning)]',
        danger: 'bg-[var(--danger-light)] text-[var(--danger)]',
        secondary: 'bg-[var(--bg)] text-[var(--text-muted)]',
        outline: 'border border-[var(--border)] text-[var(--text)]',
        accent: 'bg-[var(--accent-light)] text-[var(--accent-dark)]',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  }
)

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return <div className={cn(badgeVariants({ variant }), className)} {...props} />
}

export { Badge, badgeVariants }
