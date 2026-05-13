import { useState } from 'react'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { DataTable } from '@/components/data-table'
import { CreateUnitButton } from './-components/create-button'
import { unitColumns } from './-components/list/table'
import { useUnitList } from './-components/list/service'
import { HouseholdMembersSection } from './-components/household-members'
import type { Unit } from '@/types'

export function UnitsPage() {
  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [selectedUnit, setSelectedUnit] = useState<Unit | null>(null)

  const params = {
    ...(typeFilter !== 'all' && { type: typeFilter }),
    ...(statusFilter !== 'all' && { status: statusFilter }),
  }

  const { data, isLoading } = useUnitList(params)
  const units = data?.data ?? []

  const columnsWithAction = [
    ...unitColumns,
    {
      id: 'household',
      header: '',
      cell: ({ row }: { row: { original: Unit } }) => (
        <Button
          variant="ghost"
          size="sm"
          className="text-[var(--text-muted)] hover:text-[var(--text)]"
          onClick={() => setSelectedUnit(row.original)}
        >
          Members
        </Button>
      ),
    },
  ]

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text)]">Units</h1>
          <p className="text-sm text-[var(--text-muted)] mt-0.5">{data?.total ?? 0} total units</p>
        </div>
        <CreateUnitButton />
      </div>

      <div className="flex gap-3">
        <Select value={typeFilter} onValueChange={setTypeFilter}>
          <SelectTrigger className="w-36">
            <SelectValue placeholder="Type" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Types</SelectItem>
            <SelectItem value="apartment">Apartment</SelectItem>
            <SelectItem value="villa">Villa</SelectItem>
            <SelectItem value="penthouse">Penthouse</SelectItem>
            <SelectItem value="studio">Studio</SelectItem>
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-36">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Status</SelectItem>
            <SelectItem value="occupied">Occupied</SelectItem>
            <SelectItem value="vacant">Vacant</SelectItem>
            <SelectItem value="maintenance">Maintenance</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <DataTable
        columns={columnsWithAction}
        data={units}
        searchPlaceholder="Search by unit number, building..."
        isLoading={isLoading}
      />

      <Dialog
        open={selectedUnit !== null}
        onOpenChange={(open) => { if (!open) setSelectedUnit(null) }}
      >
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>
              Unit {selectedUnit?.number}
              {selectedUnit?.building ? ` — ${selectedUnit.building}` : ''}
            </DialogTitle>
          </DialogHeader>
          {selectedUnit && (
            <HouseholdMembersSection unitId={selectedUnit.id} />
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}
