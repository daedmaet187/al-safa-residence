import { z } from 'zod'

export const createResidentSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email'),
  phone: z.string().min(7, 'Invalid phone number'),
  role: z.enum(['resident', 'admin', 'security']),
  password: z.string().min(8, 'Password must be at least 8 characters'),
})

export const updateResidentSchema = z.object({
  name: z.string().min(2).optional(),
  email: z.string().email().optional(),
  phone: z.string().min(7).optional(),
  role: z.enum(['resident', 'admin', 'security']).optional(),
  status: z.enum(['active', 'inactive', 'suspended', 'pending']).optional(),
})

export type CreateResidentValues = z.infer<typeof createResidentSchema>
export type UpdateResidentValues = z.infer<typeof updateResidentSchema>
