import { createFileRoute } from '@tanstack/react-router'
import ConversationsPage from '@/app/conversations'

export const Route = createFileRoute('/_layout/conversations/')({
  component: ConversationsPage,
})
