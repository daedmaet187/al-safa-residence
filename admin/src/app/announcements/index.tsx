import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Plus, Trash2, Pencil, AlertCircle, Calendar } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
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
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Label } from '@/components/ui/label'
import { Skeleton } from '@/components/ui/skeleton'
import { formatDate } from '@/lib/utils'
import type { Announcement } from '@/types'
import {
  useAnnouncementList,
  useCreateAnnouncement,
  useDeleteAnnouncement,
} from './-components/service'

const announcementSchema = z.object({
  title: z.string().min(2, 'Title is required'),
  body: z.string().min(10, 'Body must be at least 10 characters'),
  isImportant: z.boolean(),
  expiresAt: z.string().optional(),
})
type AnnouncementValues = z.infer<typeof announcementSchema>

function CreateAnnouncementDialog() {
  const [open, setOpen] = useState(false)
  const { mutate, isPending } = useCreateAnnouncement()

  const form = useForm<AnnouncementValues>({
    resolver: zodResolver(announcementSchema),
    defaultValues: { title: '', body: '', isImportant: false, expiresAt: '' },
  })

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button><Plus className="h-4 w-4" /> New Announcement</Button>
      </DialogTrigger>
      <DialogContent className="max-w-xl">
        <DialogHeader><DialogTitle>New Announcement</DialogTitle></DialogHeader>
        <Form {...form}>
          <form
            onSubmit={form.handleSubmit((v) => mutate(v, { onSuccess: () => { setOpen(false); form.reset() } }))}
            className="space-y-4"
          >
            <FormField control={form.control} name="title" render={({ field }) => (
              <FormItem>
                <FormLabel>Title</FormLabel>
                <FormControl><Input placeholder="Important: Pool maintenance schedule" {...field} /></FormControl>
                <FormMessage />
              </FormItem>
            )} />
            <FormField control={form.control} name="body" render={({ field }) => (
              <FormItem>
                <FormLabel>Content</FormLabel>
                <FormControl>
                  <Textarea
                    placeholder="Write your announcement here..."
                    rows={5}
                    {...field}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )} />
            <div className="grid grid-cols-2 gap-4">
              <FormField control={form.control} name="isImportant" render={({ field }) => (
                <FormItem className="flex items-center gap-3">
                  <FormControl>
                    <Switch checked={field.value} onCheckedChange={field.onChange} />
                  </FormControl>
                  <FormLabel className="!mt-0">Mark as Important</FormLabel>
                </FormItem>
              )} />
              <FormField control={form.control} name="expiresAt" render={({ field }) => (
                <FormItem>
                  <FormLabel>Expires At (optional)</FormLabel>
                  <FormControl><Input type="date" {...field} /></FormControl>
                  <FormMessage />
                </FormItem>
              )} />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</Button>
              <Button type="submit" disabled={isPending}>{isPending ? 'Publishing...' : 'Publish'}</Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}

function AnnouncementCard({ announcement }: { announcement: Announcement }) {
  const { mutate: deleteAnn } = useDeleteAnnouncement()

  return (
    <Card className={announcement.isImportant ? 'border-[var(--accent)]/40' : ''}>
      <CardContent className="p-5">
        <div className="flex items-start justify-between gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              {announcement.isImportant && (
                <Badge variant="accent" className="text-xs">
                  <AlertCircle className="h-3 w-3 mr-1" /> Important
                </Badge>
              )}
              <h3 className="font-semibold text-[var(--text)]">{announcement.title}</h3>
            </div>
            <p className="text-sm text-[var(--text-muted)] line-clamp-3 mt-1">{announcement.body}</p>
            <div className="flex items-center gap-3 mt-3 text-xs text-[var(--text-subtle)]">
              <span>{formatDate(announcement.createdAt)}</span>
              {announcement.expiresAt && (
                <span className="flex items-center gap-1">
                  <Calendar className="h-3 w-3" />
                  Expires {formatDate(announcement.expiresAt)}
                </span>
              )}
            </div>
          </div>
          <div className="flex gap-1 shrink-0">
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <Pencil className="h-3.5 w-3.5" />
            </Button>
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-[var(--danger)] hover:text-[var(--danger)]"
              onClick={() => deleteAnn(announcement.id)}
            >
              <Trash2 className="h-3.5 w-3.5" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export function AnnouncementsPage() {
  const { data, isLoading } = useAnnouncementList()
  const announcements = data?.data ?? []

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[var(--text)]">Announcements</h1>
          <p className="text-sm text-[var(--text-muted)] mt-0.5">{data?.total ?? 0} total announcements</p>
        </div>
        <CreateAnnouncementDialog />
      </div>

      <div className="space-y-3">
        {isLoading ? (
          Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}>
              <CardContent className="p-5 space-y-2">
                <Skeleton className="h-4 w-1/2" />
                <Skeleton className="h-3 w-full" />
                <Skeleton className="h-3 w-3/4" />
              </CardContent>
            </Card>
          ))
        ) : announcements.length ? (
          announcements.map((a) => <AnnouncementCard key={a.id} announcement={a} />)
        ) : (
          <div className="text-center py-16 text-[var(--text-muted)]">
            <p className="font-medium">No announcements yet</p>
            <p className="text-sm mt-1">Create your first announcement to notify residents</p>
          </div>
        )}
      </div>
    </div>
  )
}
