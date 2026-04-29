import { z } from 'zod'

export const createBillSchema = z.object({
  residentId: z.string().min(1, 'Resident is required'),
  unitId: z.string().min(1, 'Unit is required'),
  type: z.enum(['maintenance_fee', 'utility', 'parking', 'amenity', 'other']),
  amount: z.coerce.number().positive('Amount must be positive'),
  dueDate: z.string().min(1, 'Due date is required'),
})

export type CreateBillValues = z.infer<typeof createBillSchema>
