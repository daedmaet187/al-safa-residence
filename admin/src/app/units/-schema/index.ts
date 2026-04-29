import { z } from 'zod'

export const createUnitSchema = z.object({
  number: z.string().min(1, 'Unit number is required'),
  floor: z.coerce.number().min(0),
  building: z.string().optional(),
  type: z.enum(['apartment', 'villa', 'penthouse', 'studio']),
  area: z.coerce.number().positive('Area must be positive'),
  bedrooms: z.coerce.number().min(0).optional(),
  bathrooms: z.coerce.number().min(0).optional(),
})

export type CreateUnitValues = z.infer<typeof createUnitSchema>
