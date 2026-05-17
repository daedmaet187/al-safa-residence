import { z } from 'zod'

export const createBillSchema = z.object({
  userId: z.string().min(1, 'Resident is required'),
  unitId: z.string().min(1, 'Unit is required'),
  type: z.enum(['MONTHLY_FEE', 'UTILITIES', 'MAINTENANCE_FEE', 'PARKING', 'OTHER']),
  amount: z.coerce.number().positive('Amount must be positive'),
  dueDate: z.string().min(1, 'Due date is required'),
  description: z.string().optional(),
})

export type CreateBillValues = z.infer<typeof createBillSchema>
