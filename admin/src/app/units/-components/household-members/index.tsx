import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import api from '@/lib/axios'
import { queryKeys } from '@/lib/query-keys'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import type { HouseholdMember } from '@/types'

interface HouseholdMembersResponse {
  members: HouseholdMember[]
  primaryResident: { id: string; name: string } | null
}

function useHouseholdMembers(unitId: string) {
  return useQuery({
    queryKey: queryKeys.householdMembers.byUnit(unitId),
    queryFn: async () => {
      const { data } = await api.get<HouseholdMembersResponse>(
        `/admin/units/${unitId}/household-members`,
      )
      return data
    },
  })
}

function useDeactivateMember(unitId: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (memberId: string) => {
      await api.patch(`/admin/units/${unitId}/household-members/${memberId}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: queryKeys.householdMembers.byUnit(unitId),
      })
      toast.success('Household member deactivated')
    },
    onError: () => toast.error('Failed to deactivate household member'),
  })
}

interface Props {
  unitId: string
}

export function HouseholdMembersSection({ unitId }: Props) {
  const { data, isLoading } = useHouseholdMembers(unitId)
  const deactivate = useDeactivateMember(unitId)

  const members = data?.members ?? []

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-base font-semibold text-[var(--text)]">
            Household Members
          </h3>
          {data?.primaryResident && (
            <p className="text-xs text-[var(--text-muted)] mt-0.5">
              Primary: {data.primaryResident.name}
            </p>
          )}
        </div>
        <span className="text-xs text-[var(--text-muted)]">
          {members.length} member{members.length !== 1 ? 's' : ''}
        </span>
      </div>

      {isLoading ? (
        <div className="text-sm text-[var(--text-muted)] py-4 text-center">
          Loading...
        </div>
      ) : members.length === 0 ? (
        <div className="rounded-xl border border-[var(--border)] bg-[var(--surface-raised)] px-4 py-6 text-center text-sm text-[var(--text-muted)]">
          No household members registered
        </div>
      ) : (
        <div className="rounded-xl border border-[var(--border)] overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-[var(--border)] bg-[var(--surface-raised)]">
                <th className="px-4 py-2.5 text-left font-medium text-[var(--text-muted)]">
                  Name
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-[var(--text-muted)]">
                  Relationship
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-[var(--text-muted)]">
                  Phone
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-[var(--text-muted)]">
                  Access
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-[var(--text-muted)]">
                  Status
                </th>
                <th className="px-4 py-2.5 text-left font-medium text-[var(--text-muted)]">
                  Added
                </th>
                <th className="px-4 py-2.5" />
              </tr>
            </thead>
            <tbody>
              {members.map((m, idx) => (
                <tr
                  key={m.id}
                  className={
                    idx < members.length - 1
                      ? 'border-b border-[var(--border)]'
                      : ''
                  }
                >
                  <td className="px-4 py-3 font-medium text-[var(--text)]">
                    {m.name}
                  </td>
                  <td className="px-4 py-3 text-[var(--text-muted)] capitalize">
                    {m.relationship}
                  </td>
                  <td className="px-4 py-3 text-[var(--text-muted)]">
                    {m.phone}
                  </td>
                  <td className="px-4 py-3">
                    <Badge
                      variant={m.accessLevel === 'FULL' ? 'warning' : 'secondary' as any}
                    >
                      {m.accessLevel === 'FULL' ? 'Full' : 'Limited'}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Badge variant={m.isActive ? 'success' : 'danger' as any}>
                      {m.isActive ? 'Active' : 'Inactive'}
                    </Badge>
                  </td>
                  <td className="px-4 py-3 text-[var(--text-muted)]">
                    {new Date(m.createdAt).toLocaleDateString()}
                  </td>
                  <td className="px-4 py-3">
                    {m.isActive && (
                      <Button
                        size="sm"
                        variant="ghost"
                        className="text-[var(--danger)] hover:text-[var(--danger)] hover:bg-[var(--danger-light)]"
                        disabled={deactivate.isPending}
                        onClick={() => deactivate.mutate(m.id)}
                      >
                        Deactivate
                      </Button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
