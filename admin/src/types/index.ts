export type UserRole = 'admin' | 'resident' | 'security'
export type UserStatus = 'active' | 'inactive' | 'suspended' | 'pending'

export type UnitType = 'apartment' | 'villa' | 'penthouse' | 'studio'
export type UnitStatus = 'occupied' | 'vacant' | 'maintenance'

export type BillType = 'monthly_fee' | 'utilities' | 'maintenance_fee' | 'parking' | 'other'
export type BillStatus = 'pending' | 'paid' | 'overdue' | 'cancelled'

export type MaintenanceCategory = 'plumbing' | 'electrical' | 'hvac' | 'structural' | 'cleaning' | 'other'
export type MaintenancePriority = 'low' | 'medium' | 'high' | 'urgent'
export type MaintenanceStatus = 'pending' | 'in_progress' | 'resolved' | 'cancelled'

export type GuestPassStatus = 'active' | 'used' | 'expired' | 'revoked'
export type GateLogResult = 'approved' | 'denied'

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
  totalPages: number
}

export interface ApiError {
  message: string
  statusCode: number
}

export interface Resident {
  id: string
  name: string
  email: string
  phone: string
  role: UserRole
  status: UserStatus
  units: UnitSummary[]
  createdAt: string
  updatedAt: string
}

export interface UnitSummary {
  id: string
  number: string
  building?: string
  type: UnitType
}

export interface Unit {
  id: string
  number: string
  floor: number
  building?: string
  type: UnitType
  area: number
  bedrooms?: number
  bathrooms?: number
  status: UnitStatus
  residents: ResidentSummary[]
  createdAt: string
  updatedAt: string
}

export interface ResidentSummary {
  id: string
  name: string
  email: string
  role: UserRole
}

export interface Bill {
  id: string
  resident: ResidentSummary
  unit: UnitSummary
  type: BillType
  amount: number
  dueDate: string
  status: BillStatus
  paidAt?: string
  createdAt: string
}

export interface Payment {
  id: string
  bill: Bill
  amount: number
  method: string
  reference?: string
  paidAt: string
}

export interface MaintenanceRequest {
  id: string
  title: string
  description: string
  resident: ResidentSummary
  unit: UnitSummary
  category: MaintenanceCategory
  priority: MaintenancePriority
  status: MaintenanceStatus
  photos: string[]
  adminNotes?: string
  timeline: MaintenanceTimelineEntry[]
  submittedAt: string
  updatedAt: string
}

export interface MaintenanceTimelineEntry {
  id: string
  status: MaintenanceStatus
  note?: string
  createdAt: string
  createdBy: string
}

export interface GuestPass {
  id: string
  guestName: string
  guestPhone?: string
  resident: ResidentSummary
  unit: UnitSummary
  qrCode: string
  validUntil: string
  status: GuestPassStatus
  createdAt: string
}

export interface GateLog {
  id: string
  guestName: string
  guestPass?: GuestPass
  unit?: UnitSummary
  result: GateLogResult
  officer?: string
  scannedAt: string
}

export interface Announcement {
  id: string
  title: string
  body: string
  isImportant: boolean
  priority?: 'normal' | 'urgent'
  expiresAt?: string
  createdAt: string
  updatedAt: string
}

export type HouseholdAccessLevel = 'FULL' | 'LIMITED'

export interface HouseholdMember {
  id: string
  primaryUserId: string
  phone: string
  name: string
  relationship: string
  accessLevel: HouseholdAccessLevel
  isActive: boolean
  createdAt: string
  updatedAt: string
}

export interface StaffMember {
  id: string
  name: string
  email: string
  role: 'admin' | 'security'
  status: UserStatus
  createdAt: string
}

export type ConversationStatus = 'open' | 'closed'
export type MessageSenderType = 'resident' | 'admin'

export interface Message {
  id: string
  conversationId: string
  senderId: string
  senderType: MessageSenderType
  content: string
  isRead: boolean
  createdAt: string
}

export interface Conversation {
  id: string
  residentId: string
  resident?: { id: string; name: string; phone?: string | null }
  unitId?: string | null
  unit?: { id: string; number: string } | null
  subject: string
  status: ConversationStatus
  createdAt: string
  updatedAt: string
  messages?: Message[]
  unreadCount?: number
}

export interface DashboardStats {
  totalResidents: number
  totalUnits: number
  occupiedUnits: number
  pendingMaintenance: number
  overdueBills: number
  activeGuestPasses: number
  recentActivity: ActivityItem[]
}

export interface ActivityItem {
  id: string
  type: 'maintenance' | 'payment' | 'guest_pass' | 'announcement' | 'resident'
  message: string
  createdAt: string
}
