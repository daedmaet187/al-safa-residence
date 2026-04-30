import { z } from 'zod'

export const createResidentSchema = z.object({
  firstName: z.string().min(2, 'First name required'),
  lastName: z.string().min(2, 'Last name required'),
  phone: z.string().min(7, 'Valid phone number required'),
  email: z.string().email('Invalid email').optional().or(z.literal('')),
  unitId: z.string().optional(),
  nationalId: z.string().optional(),
  moveInDate: z.string().optional(),
})

export const updateResidentSchema = z.object({
  firstName: z.string().min(2).optional(),
  lastName: z.string().min(2).optional(),
  phone: z.string().min(7).optional(),
  email: z.string().email().optional(),
  status: z.enum(['active', 'inactive', 'suspended', 'pending']).optional(),
  isActive: z.boolean().optional(),
})

export type CreateResidentValues = z.infer<typeof createResidentSchema>
export type UpdateResidentValues = z.infer<typeof updateResidentSchema>
