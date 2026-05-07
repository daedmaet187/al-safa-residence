import { useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Button } from '@/components/ui/button'
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetBody, SheetFooter } from '@/components/ui/sheet'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { useCreateAmenity, useUpdateAmenity } from './list/service'
import type { Amenity } from '@/types'

const amenitySchema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string().optional(),
  location: z.string().optional(),
  capacity: z.coerce.number().int().min(1, 'Capacity must be at least 1'),
  operatingHours: z.string().optional(),
})

type AmenityFormValues = z.infer<typeof amenitySchema>

interface AmenityFormProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  amenity?: Amenity | null
}

export function AmenityForm({ open, onOpenChange, amenity }: AmenityFormProps) {
  const isEditing = !!amenity
  const { mutate: create, isPending: creating } = useCreateAmenity()
  const { mutate: update, isPending: updating } = useUpdateAmenity(amenity?.id ?? '')
  const isPending = creating || updating

  const form = useForm<AmenityFormValues>({
    resolver: zodResolver(amenitySchema),
    defaultValues: { name: '', description: '', location: '', capacity: 1, operatingHours: '' },
  })

  useEffect(() => {
    if (open) {
      form.reset({
        name: amenity?.name ?? '',
        description: amenity?.description ?? '',
        location: amenity?.location ?? '',
        capacity: amenity?.capacity ?? 1,
        operatingHours: amenity?.operatingHours
          ? JSON.stringify(amenity.operatingHours, null, 2)
          : '',
      })
    }
  }, [open, amenity])

  function onSubmit(values: AmenityFormValues) {
    let operatingHours: Record<string, string> | undefined
    if (values.operatingHours) {
      try {
        operatingHours = JSON.parse(values.operatingHours)
      } catch {
        operatingHours = undefined
      }
    }

    const payload = {
      name: values.name,
      ...(values.description && { description: values.description }),
      ...(values.location && { location: values.location }),
      capacity: values.capacity,
      ...(operatingHours && { operatingHours }),
    }

    if (isEditing) {
      update(payload, { onSuccess: () => { onOpenChange(false) } })
    } else {
      create(payload, { onSuccess: () => { onOpenChange(false) } })
    }
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent>
        <SheetHeader>
          <SheetTitle>{isEditing ? 'Edit Amenity' : 'Add Amenity'}</SheetTitle>
        </SheetHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="flex flex-col h-full">
            <SheetBody className="space-y-4">
              <FormField control={form.control} name="name" render={({ field }) => (
                <FormItem>
                  <FormLabel>Name <span className="text-[var(--danger)]">*</span></FormLabel>
                  <FormControl><Input placeholder="Swimming Pool" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />

              <FormField control={form.control} name="description" render={({ field }) => (
                <FormItem>
                  <FormLabel>Description</FormLabel>
                  <FormControl>
                    <Textarea placeholder="Describe this amenity..." rows={3} {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )} />

              <div className="grid grid-cols-2 gap-4">
                <FormField control={form.control} name="location" render={({ field }) => (
                  <FormItem>
                    <FormLabel>Location</FormLabel>
                    <FormControl><Input placeholder="Ground Floor" {...field} /></FormControl>
                    <FormMessage />
                  </FormItem>
                )} />

                <FormField control={form.control} name="capacity" render={({ field }) => (
                  <FormItem>
                    <FormLabel>Capacity <span className="text-[var(--danger)]">*</span></FormLabel>
                    <FormControl><Input type="number" min={1} {...field} /></FormControl>
                    <FormMessage />
                  </FormItem>
                )} />
              </div>

              <FormField control={form.control} name="operatingHours" render={({ field }) => (
                <FormItem>
                  <FormLabel>Operating Hours (JSON)</FormLabel>
                  <FormControl>
                    <Textarea
                      placeholder={'{"monday": "8:00-22:00", "friday": "10:00-20:00"}'}
                      rows={4}
                      {...field}
                    />
                  </FormControl>
                  <p className="text-xs text-[var(--text-muted)]">Optional. JSON object with day keys.</p>
                  <FormMessage />
                </FormItem>
              )} />
            </SheetBody>

            <SheetFooter>
              <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
                Cancel
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? 'Saving...' : isEditing ? 'Save Changes' : 'Create Amenity'}
              </Button>
            </SheetFooter>
          </form>
        </Form>
      </SheetContent>
    </Sheet>
  )
}
