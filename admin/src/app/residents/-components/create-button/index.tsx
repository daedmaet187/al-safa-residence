import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from '@/components/ui/dialog'
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { createResidentSchema, type CreateResidentValues } from '../../-schema'
import { useCreateResident } from '../list/service'
import { useUnitList } from '@/app/units/-components/list/service'

export function CreateResidentButton() {
  const [open, setOpen] = useState(false)
  const { mutate, isPending } = useCreateResident()
  const { data: unitsData } = useUnitList({ take: 100 })
  const units = unitsData?.data ?? []

  const form = useForm<CreateResidentValues>({
    resolver: zodResolver(createResidentSchema),
    defaultValues: {
      firstName: '',
      lastName: '',
      phone: '',
      email: '',
      unitId: '',
      nationalId: '',
      moveInDate: '',
    },
  })

  function onSubmit(values: CreateResidentValues) {
    // strip empty optional strings
    const payload = {
      ...values,
      email: values.email || undefined,
      unitId: values.unitId || undefined,
      nationalId: values.nationalId || undefined,
      moveInDate: values.moveInDate || undefined,
    }
    mutate(payload, {
      onSuccess: () => {
        setOpen(false)
        form.reset()
      },
    })
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>
          <Plus className="h-4 w-4" /> Add Resident
        </Button>
      </DialogTrigger>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Add New Resident</DialogTitle>
          <p className="text-sm text-[var(--text-muted)]">
            The resident will log in using their phone number + OTP. No password needed.
          </p>
        </DialogHeader>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              {/* First Name */}
              <FormField control={form.control} name="firstName" render={({ field }) => (
                <FormItem>
                  <FormLabel>First Name <span className="text-[var(--danger)]">*</span></FormLabel>
                  <FormControl><Input placeholder="Ahmed" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />

              {/* Last Name */}
              <FormField control={form.control} name="lastName" render={({ field }) => (
                <FormItem>
                  <FormLabel>Last Name <span className="text-[var(--danger)]">*</span></FormLabel>
                  <FormControl><Input placeholder="Al-Rashidi" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />

              {/* Phone — primary login identifier */}
              <FormField control={form.control} name="phone" render={({ field }) => (
                <FormItem className="col-span-2">
                  <FormLabel>Phone Number <span className="text-[var(--danger)]">*</span></FormLabel>
                  <FormControl>
                    <Input
                      placeholder="+964 770 123 4567"
                      {...field}
                    />
                  </FormControl>
                  <p className="text-xs text-[var(--text-muted)]">This is how the resident logs in — must be unique.</p>
                  <FormMessage />
                </FormItem>
              )} />

              {/* Unit assignment */}
              <FormField control={form.control} name="unitId" render={({ field }) => (
                <FormItem className="col-span-2">
                  <FormLabel>Assign Unit</FormLabel>
                  <Select onValueChange={field.onChange} value={field.value}>
                    <FormControl>
                      <SelectTrigger>
                        <SelectValue placeholder="Select a unit (optional)" />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {units.map((u) => (
                        <SelectItem key={u.id} value={u.id}>
                          {u.building ? `Building ${u.building} — ` : ''}{u.number} ({u.type})
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )} />

              {/* Move-in date */}
              <FormField control={form.control} name="moveInDate" render={({ field }) => (
                <FormItem>
                  <FormLabel>Move-in Date</FormLabel>
                  <FormControl><Input type="date" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />

              {/* National ID */}
              <FormField control={form.control} name="nationalId" render={({ field }) => (
                <FormItem>
                  <FormLabel>National ID</FormLabel>
                  <FormControl><Input placeholder="ID number" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />

              {/* Email (optional) */}
              <FormField control={form.control} name="email" render={({ field }) => (
                <FormItem className="col-span-2">
                  <FormLabel>Email <span className="text-[var(--text-muted)] font-normal">(optional)</span></FormLabel>
                  <FormControl><Input type="email" placeholder="ahmed@example.com" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
            </div>

            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? 'Creating...' : 'Create Resident'}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}
