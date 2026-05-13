import { useState } from 'react'
import { Plus } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DataTable } from '@/components/data-table'
import { amenityColumns } from './-components/list/table'
import { useAmenityList, useDeactivateAmenity } from './-components/list/service'
import { AmenityForm } from './-components/amenity-form'
import type { Amenity } from '@/types'

export function AmenitiesPage() {
  const [formOpen, setFormOpen] = useState(false)
  const [selectedAmenity, setSelectedAmenity] = useState<Amenity | null>(null)

  const { data, isLoading } = useAmenityList()
  const amenities = data?.data ?? []
  const { mutate: deactivate } = useDeactivateAmenity()

  function openCreate() {
    setSelectedAmenity(null)
    setFormOpen(true)
  }

  function openEdit(amenity: Amenity) {
    setSelectedAmenity(amenity)
    setFormOpen(true)
  }

  const columnsWithActions = [
    ...amenityColumns,
    {
      id: 'actions',
      header: '',
      cell: ({ row }: { row: { original: Amenity } }) => (
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            size="sm"
            className="text-[var(--text-muted)] hover:text-[var(--text)]"
            onClick={() => openEdit(row.original)}
          >
            Edit
          </Button>
          {row.original.isActive && (
            <Button
              variant="ghost"
              size="sm"
              className="text-[var(--danger)] hover:text-[var(--danger)]"
              onClick={() => deactivate(row.original.id)}
            >
              Deactivate
            </Button>
          )}
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text)]">Amenities</h1>
          <p className="text-sm text-[var(--text-muted)] mt-0.5">{data?.total ?? 0} facilities</p>
        </div>
        <Button onClick={openCreate}>
          <Plus className="h-4 w-4" /> Add Amenity
        </Button>
      </div>

      <DataTable
        columns={columnsWithActions}
        data={amenities}
        searchPlaceholder="Search amenities..."
        isLoading={isLoading}
      />

      <AmenityForm
        open={formOpen}
        onOpenChange={setFormOpen}
        amenity={selectedAmenity}
      />
    </div>
  )
}
