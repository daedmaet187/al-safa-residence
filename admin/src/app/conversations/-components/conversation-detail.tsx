import { useState, useEffect, useRef } from 'react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { formatDate } from '@/lib/utils'
import type { Conversation } from '@/types'
import {
  useConversationDetail,
  useAdminSendMessage,
  useUpdateConversationStatus,
  useMarkConversationRead,
} from './service'

function ChatBubble({ senderType, content, createdAt }: { senderType: string; content: string; createdAt: string }) {
  const isAdmin = senderType === 'admin'
  return (
    <div className={`flex ${isAdmin ? 'justify-end' : 'justify-start'} mb-3`}>
      <div
        className={`max-w-[70%] rounded-2xl px-4 py-2.5 text-sm ${
          isAdmin
            ? 'bg-[var(--primary)] text-white rounded-br-sm'
            : 'bg-[var(--surface-raised,var(--surface))] border border-[var(--border)] text-[var(--text)] rounded-bl-sm'
        }`}
      >
        <p className="whitespace-pre-wrap break-words">{content}</p>
        <p className={`text-xs mt-1 ${isAdmin ? 'text-white/60' : 'text-[var(--text-muted)]'}`}>
          {formatDate(createdAt)}
        </p>
      </div>
    </div>
  )
}

export function ConversationDetail({
  conversationId,
  open,
  onClose,
}: {
  conversationId: string
  open: boolean
  onClose: () => void
}) {
  const [reply, setReply] = useState('')
  const bottomRef = useRef<HTMLDivElement>(null)

  const { data: conversation, isLoading } = useConversationDetail(conversationId)
  const { mutate: sendMessage, isPending: sending } = useAdminSendMessage()
  const { mutate: updateStatus, isPending: updatingStatus } = useUpdateConversationStatus()
  const { mutate: markRead } = useMarkConversationRead()

  // Mark read when opened
  useEffect(() => {
    if (open && conversationId) markRead(conversationId)
  }, [open, conversationId]) // eslint-disable-line react-hooks/exhaustive-deps

  // Scroll to bottom when messages change
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [conversation?.messages?.length])

  function handleSend() {
    if (!reply.trim()) return
    sendMessage(
      { id: conversationId, content: reply.trim() },
      { onSuccess: () => setReply('') },
    )
  }

  function handleKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) handleSend()
  }

  const isClosed = conversation?.status === 'closed'

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl h-[80vh] flex flex-col p-0 gap-0">
        <DialogHeader className="px-6 py-4 border-b border-[var(--border)] shrink-0">
          <div className="flex items-start justify-between gap-4">
            <div>
              <DialogTitle className="text-base">{conversation?.subject ?? '—'}</DialogTitle>
              <p className="text-sm text-[var(--text-muted)] mt-0.5">
                {conversation?.resident?.name ?? '—'}
                {conversation?.unit ? ` · Unit ${conversation.unit.number}` : ''}
              </p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <Badge variant={isClosed ? 'secondary' : 'success'}>
                {conversation?.status ?? '—'}
              </Badge>
              {conversation && (
                <Button
                  variant="outline"
                  size="sm"
                  disabled={updatingStatus}
                  onClick={() =>
                    updateStatus(
                      { id: conversationId, status: isClosed ? 'open' : 'closed' },
                      { onSuccess: onClose },
                    )
                  }
                >
                  {isClosed ? 'Reopen' : 'Close'}
                </Button>
              )}
            </div>
          </div>
        </DialogHeader>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto px-6 py-4 min-h-0">
          {isLoading ? (
            <div className="flex items-center justify-center h-full text-sm text-[var(--text-muted)]">
              Loading…
            </div>
          ) : (conversation?.messages ?? []).length === 0 ? (
            <div className="flex items-center justify-center h-full text-sm text-[var(--text-muted)]">
              No messages yet
            </div>
          ) : (
            <>
              {(conversation?.messages ?? []).map((msg) => (
                <ChatBubble
                  key={msg.id}
                  senderType={msg.senderType}
                  content={msg.content}
                  createdAt={msg.createdAt}
                />
              ))}
              <div ref={bottomRef} />
            </>
          )}
        </div>

        {/* Reply box */}
        {!isClosed && (
          <div className="px-6 py-4 border-t border-[var(--border)] shrink-0">
            <Textarea
              placeholder="Type a reply… (Ctrl+Enter to send)"
              value={reply}
              onChange={(e) => setReply(e.target.value)}
              onKeyDown={handleKeyDown}
              rows={3}
              className="resize-none"
            />
            <div className="flex justify-end mt-2">
              <Button onClick={handleSend} disabled={sending || !reply.trim()}>
                {sending ? 'Sending…' : 'Send Reply'}
              </Button>
            </div>
          </div>
        )}
        {isClosed && (
          <div className="px-6 py-3 border-t border-[var(--border)] text-center text-sm text-[var(--text-muted)] shrink-0">
            This conversation is closed.
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}
