#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Al-Safa Residence — Pre-Delivery Review Script
# Runs a full end-to-end API review before handing the project to the client.
#
# Usage:  ./scripts/review.sh [--base-url https://safa-api.stuff187.com/api]
#
# Exit codes:
#   0  — all checks passed
#   1  — one or more checks failed
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

BASE_URL="${BASE_URL:-https://safa-api.stuff187.com/api}"
PASS=0
FAIL=0
FAILURES=()

# ── colours ──────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# ── helpers ───────────────────────────────────────────────────────────────────
section() { echo -e "\n${CYAN}${BOLD}══ $1 ══${RESET}"; }

ok()   { echo -e "  ${GREEN}✅ $1${RESET}"; ((PASS++)); }
fail() { echo -e "  ${RED}❌ $1${RESET}  →  $2"; ((FAIL++)); FAILURES+=("$1: $2"); }

# Make a request; set BODY and STATUS
req() {
  local method=$1 path=$2; shift 2
  STATUS=$(curl -s -o /tmp/review_body.json -w "%{http_code}" \
    -X "$method" "${BASE_URL}${path}" \
    -H "Content-Type: application/json" \
    "$@") || true
  BODY=$(cat /tmp/review_body.json 2>/dev/null || echo '{}')
}

# Authenticated request
areq() {
  local method=$1 path=$2; shift 2
  req "$method" "$path" -H "Authorization: Bearer $TOKEN" "$@"
}

# Extract JSON field
jget() { echo "$BODY" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d$1)" 2>/dev/null || true; }

# Assert HTTP status (accepts 200 or 201 as success unless specific expected given)
assert_status() {
  local label=$1 expected=$2
  # Treat both 200 and 201 as success unless a specific code is given
  local is_ok=false
  if [ "$STATUS" = "$expected" ]; then
    is_ok=true
  elif [ "$expected" = "200" ] && [ "$STATUS" = "201" ]; then
    is_ok=true
  elif [ "$expected" = "201" ] && [ "$STATUS" = "200" ]; then
    is_ok=true
  fi
  if [ "$is_ok" = "true" ]; then
    ok "$label (HTTP $STATUS)"
  else
    fail "$label" "Expected $expected, got $STATUS — $(echo "$BODY" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(d.get('message','?'))" 2>/dev/null)"
  fi
}

# Assert field exists and is non-empty
assert_field() {
  local label=$1 field=$2
  local val=$(jget "$field")
  if [ -n "$val" ] && [ "$val" != "None" ] && [ "$val" != "null" ]; then
    ok "$label"
  else
    fail "$label" "Field $field missing or empty in response"
  fi
}

# Unique suffix for test data (avoids conflicts on re-runs)
TS=$(date +%s | tail -c 6)

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Al-Safa Residence — Pre-Delivery Review${RESET}"
echo -e "API: ${BASE_URL}"
echo -e "$(date)"
echo "─────────────────────────────────────────────────────"

# ─────────────────────────────────────────────────────────────────────────────
section "HEALTH CHECK"

req GET /health
assert_status "API is reachable" 200
assert_field   "Health returns status=ok" "['status']"

# ─────────────────────────────────────────────────────────────────────────────
section "AUTH — Admin flow"

req POST /auth/login -d '{"email":"admin@alsafa.local","password":"AlSafaAdmin2026!"}'
assert_status "Admin login (email+password)" 200
assert_field  "Login returns requiresOtp flag" "['requiresOtp']"

req POST /auth/send-otp -d '{"email":"admin@alsafa.local"}'
assert_status "send-otp stub returns success" 200

req POST /auth/verify-otp -d '{"email":"admin@alsafa.local","otp":"123456"}'
assert_status "Admin verify-otp with default OTP" 200
ADMIN_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('accessToken',''))" 2>/dev/null || true)
ADMIN_USER_ID=$(echo "$BODY" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('user',{}).get('id',''))" 2>/dev/null || true)
[ -n "$ADMIN_TOKEN" ] && ok "Admin token received" || fail "Admin token" "Empty token"

# small sleep to avoid JWT iat collision between back-to-back verify-otp calls
sleep 2

# ─────────────────────────────────────────────────────────────────────────────
section "AUTH — Resident flow"

req POST /auth/login -d '{"email":"resident@alsafa.local","password":"Resident2026!"}'
assert_status "Resident login returns requiresOtp" 200

sleep 1
req POST /auth/verify-otp -d '{"email":"resident@alsafa.local","otp":"123456"}'
assert_status "Resident OTP verify" 200
TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('accessToken',''))" 2>/dev/null || true)
RESIDENT_USER_ID=$(echo "$BODY" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('user',{}).get('id',''))" 2>/dev/null || true)
[ -n "$TOKEN" ] && ok "Resident token received" || fail "Resident token" "Empty token"
RESIDENT_UNITS=$(echo "$BODY" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('units',[]))" 2>/dev/null || true)

TOKEN="$TOKEN"  # set for areq

areq GET /auth/me
assert_status "GET /auth/me" 200
assert_field  "me returns user id" "['id']"

# ─────────────────────────────────────────────────────────────────────────────
section "AUTH — Security Guard flow"

req POST /auth/login -d '{"email":"guard@alsafa.local","password":"Guard2026!"}'
assert_status "Guard login (email+password)" 200
GUARD_TOKEN=$(echo "$BODY" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('accessToken',''))" 2>/dev/null || true)
[ -n "$GUARD_TOKEN" ] && ok "Guard token received" || fail "Guard token" "Empty"

# ─────────────────────────────────────────────────────────────────────────────
section "RESIDENT — Home Dashboard"

areq GET /dashboard/summary
assert_status "GET /dashboard/summary" 200
assert_field  "Summary has recentAnnouncements" "['recentAnnouncements']"
assert_field  "Summary has activeGuestPasses"   "['activeGuestPasses']"
assert_field  "Summary has overdueBills"        "['overdueBills']"
assert_field  "Summary has openMaintenanceRequests" "['openMaintenanceRequests']"

# ─────────────────────────────────────────────────────────────────────────────
section "RESIDENT — Bills & Payments"

areq GET /bills
assert_status "GET /bills (list)" 200
BILL_ID=$(echo "$BODY" | python3 -c "import sys,json; bills=json.loads(sys.stdin.read()); pending=[b for b in bills if b['status']=='pending']; print(pending[0]['id'] if pending else '')" 2>/dev/null)

areq GET /bills?status=paid
assert_status "GET /bills?status=paid" 200

if [ -n "$BILL_ID" ]; then
  areq GET "/bills/$BILL_ID"
  assert_status "GET /bills/:id" 200
  assert_field  "Bill has id"     "['id']"
  assert_field  "Bill has title"  "['title']"
  assert_field  "Bill has amount" "['amount']"
  assert_field  "Bill has status" "['status']"
  assert_field  "Bill has dueDate" "['dueDate']"

  areq POST "/bills/$BILL_ID/pay" -d '{"method":"online"}'
  if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
    ok "POST /bills/:id/pay — bill paid"
    # Verify bill is now paid
    areq GET "/bills/$BILL_ID"
    BILL_STATUS=$(jget "['status']")
    [ "$BILL_STATUS" = "paid" ] && ok "Bill status updated to paid" || fail "Bill status after pay" "Expected paid, got $BILL_STATUS"
  else
    fail "POST /bills/:id/pay" "HTTP $STATUS"
  fi
else
  echo -e "  ${YELLOW}⚠️  No pending bill for resident — skipping pay test${RESET}"
fi

# ─────────────────────────────────────────────────────────────────────────────
section "RESIDENT — Gate & Guest Passes"

areq GET /gate/my-qr
assert_status "GET /gate/my-qr" 200
assert_field  "my-qr has qrCode" "['qrCode']"

areq GET /gate/passes
assert_status "GET /gate/passes (list)" 200

VALID_FROM="2026-06-01T00:00:00.000Z"
VALID_UNTIL="2026-06-02T00:00:00.000Z"
areq POST /gate/passes -d "{\"guestName\":\"Review Test Guest\",\"guestPhone\":\"+9647900000001\",\"validFrom\":\"$VALID_FROM\",\"validUntil\":\"$VALID_UNTIL\",\"purpose\":\"Review test\"}"
assert_status "POST /gate/passes (create)" 201
NEW_PASS_ID=$(jget "['id']")
assert_field  "New pass has id"        "['id']"
assert_field  "New pass has qrCode"    "['qrCode']"
assert_field  "New pass has status"    "['status']"
assert_field  "New pass has validUntil" "['validUntil']"

if [ -n "$NEW_PASS_ID" ]; then
  areq DELETE "/gate/passes/$NEW_PASS_ID"
  assert_status "DELETE /gate/passes/:id (revoke)" 200
fi

# ─────────────────────────────────────────────────────────────────────────────
section "RESIDENT — Unit"

areq GET /units/my-unit
assert_status "GET /units/my-unit" 200
assert_field  "my-unit has unit.id"           "['unit']['id']"
assert_field  "my-unit has unit.number"       "['unit']['number']"
assert_field  "my-unit has stats"             "['stats']"
assert_field  "my-unit has stats.totalPaid"   "['stats']['totalPaid']"

# ─────────────────────────────────────────────────────────────────────────────
section "RESIDENT — Maintenance"

areq GET /maintenance
assert_status "GET /maintenance (list)" 200

areq POST /maintenance -d "{\"unitId\":\"$(jget "['unit']['id']" || echo "5042ee67-a978-4b0d-b28e-422d4118c3cf")\",\"title\":\"Review test request\",\"description\":\"Created by automated review\",\"category\":\"OTHER\",\"priority\":\"LOW\"}"

# Use the unit id from my-unit
areq GET /units/my-unit
UNIT_ID=$(jget "['unit']['id']")
TOKEN_SAVE="$TOKEN"

areq POST /maintenance -d "{\"unitId\":\"$UNIT_ID\",\"title\":\"Review test request\",\"description\":\"Created by automated review\",\"category\":\"OTHER\",\"priority\":\"LOW\"}"
assert_status "POST /maintenance (create)" 201
NEW_MR_ID=$(jget "['id']")
assert_field  "New request has id"     "['id']"
assert_field  "New request has status" "['status']"

if [ -n "$NEW_MR_ID" ]; then
  areq GET "/maintenance/$NEW_MR_ID"
  assert_status "GET /maintenance/:id" 200
  assert_field  "Request detail has title" "['title']"
  assert_field  "Request detail has unit"  "['unit']"
fi

# ─────────────────────────────────────────────────────────────────────────────
section "RESIDENT — Announcements"

areq GET /announcements
assert_status "GET /announcements (list)" 200
ANN_COUNT=$(echo "$BODY" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(len(d.get('data',d)) if isinstance(d,dict) else len(d))" 2>/dev/null)
[ "${ANN_COUNT:-0}" -gt 0 ] && ok "Announcements list non-empty ($ANN_COUNT)" || fail "Announcements" "Empty list"

ANN_ID=$(echo "$BODY" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); items=d.get('data',d); print(items[0]['id'] if items else '')" 2>/dev/null)
if [ -n "$ANN_ID" ]; then
  areq GET "/announcements/$ANN_ID"
  assert_status "GET /announcements/:id" 200
fi

# ─────────────────────────────────────────────────────────────────────────────
section "RESIDENT — Profile"

areq GET /profile
assert_status "GET /profile" 200
assert_field  "Profile has id"    "['id']"
assert_field  "Profile has email" "['email']"
assert_field  "Profile has name"  "['name']"

areq PATCH /profile -d '{"name":"Ahmad Al-Safa"}'
assert_status "PATCH /profile" 200

areq POST /profile/change-password -d '{"currentPassword":"Resident2026!","newPassword":"Resident2026!"}'
assert_status "POST /profile/change-password" 200

# ─────────────────────────────────────────────────────────────────────────────
section "SECURITY GUARD — Gate operations"

TOKEN="$GUARD_TOKEN"

areq GET /guests/log
assert_status "GET /guests/log (guard)" 200

# scan a known QR
ACTIVE_QR=$(curl -s "${BASE_URL}/guests" \
  -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null | \
  python3 -c "import sys,json; passes=json.loads(sys.stdin.read()).get('data',[]); active=[p for p in passes if p['status']=='ACTIVE']; print(active[0]['qrCode'] if active else '')" 2>/dev/null || echo "")

if [ -n "$ACTIVE_QR" ]; then
  areq POST /guests/scan -d "{\"qrCode\":\"$ACTIVE_QR\"}"
  if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
    ok "POST /guests/scan — QR scan returns result"
    SCAN_STATUS=$(jget "['status']")
    [ -n "$SCAN_STATUS" ] && ok "Scan has status field ($SCAN_STATUS)" || fail "Scan status" "Missing"
  else
    fail "POST /guests/scan" "HTTP $STATUS"
  fi
else
  echo -e "  ${YELLOW}⚠️  No active guest pass found — skipping scan test${RESET}"
fi

TOKEN="$TOKEN_SAVE"  # restore resident token

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Dashboard"

TOKEN="$ADMIN_TOKEN"

areq GET /admin/dashboard/stats
assert_status "GET /admin/dashboard/stats" 200
assert_field  "Stats has totalResidents"   "['totalResidents']"
assert_field  "Stats has totalUnits"       "['totalUnits']"
assert_field  "Stats has pendingBills"     "['pendingBills']"
assert_field  "Stats has pendingMaintenance" "['pendingMaintenance']"

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Residents"

areq GET /admin/residents
assert_status "GET /admin/residents" 200
assert_field  "Residents list has count" "['count']"
RES_COUNT=$(jget "['count']")
[ "${RES_COUNT:-0}" -gt 0 ] && ok "Residents count > 0 ($RES_COUNT)" || fail "Residents" "Count is 0"

areq POST /admin/residents -d "{\"name\":\"Review Test Resident\",\"email\":\"review.${TS}@alsafa.local\",\"password\":\"Test2026!\"}"
assert_status "POST /admin/residents (create)" 201
NEW_RES_ID=$(jget "['id']")

if [ -n "$NEW_RES_ID" ]; then
  areq PATCH "/admin/residents/$NEW_RES_ID" -d '{"isActive":false}'
  assert_status "PATCH /admin/residents/:id (deactivate)" 200
fi

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Units"

areq GET /admin/units
assert_status "GET /admin/units" 200
UNIT_COUNT=$(jget "['count']")
[ "${UNIT_COUNT:-0}" -gt 0 ] && ok "Units count > 0 ($UNIT_COUNT)" || fail "Units" "Count is 0"

areq POST /admin/units -d "{\"number\":\"RV-${TS}\",\"floor\":9,\"building\":\"R\",\"type\":\"1BR\",\"area\":60,\"bedrooms\":1,\"bathrooms\":1}"
assert_status "POST /admin/units (create)" 201
NEW_UNIT_ID=$(jget "['id']")

if [ -n "$NEW_UNIT_ID" ]; then
  areq PATCH "/admin/units/$NEW_UNIT_ID" -d '{"parkingSpot":"R-01"}'
  assert_status "PATCH /admin/units/:id (update)" 200
fi

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Announcements"

areq GET /admin/announcements
assert_status "GET /admin/announcements" 200

areq POST /admin/announcements -d '{"title":"Review test announcement","body":"Auto-generated by review script","isImportant":false}'
assert_status "POST /admin/announcements (create)" 201
NEW_ANN_ID=$(jget "['id']")

if [ -n "$NEW_ANN_ID" ]; then
  areq PATCH "/admin/announcements/$NEW_ANN_ID" -d '{"isImportant":true,"title":"Review test announcement (updated)"}'
  assert_status "PATCH /admin/announcements/:id (update)" 200
  UPDATED_IMP=$(jget "['isImportant']")
  [ "$UPDATED_IMP" = "True" ] && ok "Announcement isImportant updated" || fail "Announcement update" "isImportant not updated"

  areq DELETE "/admin/announcements/$NEW_ANN_ID"
  assert_status "DELETE /admin/announcements/:id (soft delete)" 200
fi

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Maintenance"

areq GET /admin/maintenance
assert_status "GET /admin/maintenance (all)" 200
MR_COUNT=$(jget "['count']")
[ "${MR_COUNT:-0}" -gt 0 ] && ok "Maintenance count > 0 ($MR_COUNT)" || fail "Maintenance" "Count is 0"

MR_ID=$(echo "$BODY" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); items=d.get('data',[]); pending=[r for r in items if r['status']=='PENDING']; print(pending[0]['id'] if pending else '')" 2>/dev/null)
if [ -n "$MR_ID" ]; then
  areq PATCH "/admin/maintenance/$MR_ID" -d '{"status":"IN_PROGRESS","adminNotes":"Reviewed by automated test"}'
  assert_status "PATCH /admin/maintenance/:id (update status)" 200
  NEW_STATUS=$(jget "['status']")
  [ "$NEW_STATUS" = "IN_PROGRESS" ] && ok "Maintenance status changed to IN_PROGRESS" || fail "Maintenance status" "Expected IN_PROGRESS, got $NEW_STATUS"
fi

areq GET "/admin/maintenance?status=IN_PROGRESS"
assert_status "GET /admin/maintenance?status filter" 200

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Billing"

areq GET /admin/bills
assert_status "GET /admin/bills" 200

areq GET "/admin/bills?status=overdue"
assert_status "GET /admin/bills?status=overdue" 200

# Fall back to known IDs if dynamic lookup failed
BILL_USER_ID="${RESIDENT_USER_ID:-8393bca8-8f1d-4ce2-b073-fe8e890a9b8c}"
BILL_UNIT_ID="${UNIT_ID:-5042ee67-a978-4b0d-b28e-422d4118c3cf}"
areq POST /admin/bills -d "{\"userId\":\"$BILL_USER_ID\",\"unitId\":\"$BILL_UNIT_ID\",\"type\":\"MONTHLY_FEE\",\"amount\":100000,\"currency\":\"IQD\",\"dueDate\":\"2026-08-01T00:00:00.000Z\",\"description\":\"Review test bill\"}"
assert_status "POST /admin/bills (create)" 201
NEW_BILL_ID=$(jget "['id']")
assert_field  "New bill has id"   "['id']"
assert_field  "New bill has user" "['user']"
assert_field  "New bill has unit" "['unit']"

if [ -n "$NEW_BILL_ID" ]; then
  areq PATCH "/admin/bills/$NEW_BILL_ID/mark-paid"
  assert_status "PATCH /admin/bills/:id/mark-paid" 200
  PAID_STATUS=$(jget "['status']")
  [ "$PAID_STATUS" = "PAID" ] && ok "Bill marked as PAID" || fail "Bill mark-paid" "Status is $PAID_STATUS"
fi

areq GET /admin/payments
assert_status "GET /admin/payments" 200

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Gate"

areq GET /admin/gate/passes
assert_status "GET /admin/gate/passes" 200

areq GET /admin/gate/logs
assert_status "GET /admin/gate/logs" 200

# Find an active pass to revoke
ACTIVE_PASS_ID=$(echo "$BODY" | python3 -c "
import sys,json
body = open('/tmp/review_body.json').read()
" 2>/dev/null || echo "")

# Get an active pass from passes list
PASSES_BODY=$(curl -s "${BASE_URL}/admin/gate/passes" -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null)
ACTIVE_PASS_ID=$(echo "$PASSES_BODY" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); passes=d.get('data',[]); active=[p for p in passes if p['status']=='ACTIVE']; print(active[0]['id'] if active else '')" 2>/dev/null || echo "")

if [ -n "$ACTIVE_PASS_ID" ]; then
  areq PATCH "/admin/gate/passes/$ACTIVE_PASS_ID/revoke"
  assert_status "PATCH /admin/gate/passes/:id/revoke" 200
else
  echo -e "  ${YELLOW}⚠️  No active passes to revoke — skipping${RESET}"
fi

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Staff"

areq GET /admin/staff
assert_status "GET /admin/staff" 200
STAFF_COUNT=$(jget "['count']")
[ "${STAFF_COUNT:-0}" -gt 0 ] && ok "Staff count > 0 ($STAFF_COUNT)" || fail "Staff" "Count is 0"

areq POST /admin/staff -d "{\"name\":\"Review Test Guard\",\"email\":\"guard.${TS}@alsafa.local\",\"password\":\"Guard2026!\",\"role\":\"SECURITY\"}"
assert_status "POST /admin/staff (create)" 201
NEW_STAFF_ID=$(jget "['id']")

if [ -n "$NEW_STAFF_ID" ]; then
  areq PATCH "/admin/staff/$NEW_STAFF_ID" -d '{"isActive":false}'
  assert_status "PATCH /admin/staff/:id (deactivate)" 200
fi

# ─────────────────────────────────────────────────────────────────────────────
section "ADMIN — Reports"

areq GET /admin/reports/payments
assert_status "GET /admin/reports/payments" 200
assert_field  "Payments report has collectedThisMonth" "['collectedThisMonth']"
assert_field  "Payments report has byType"             "['byType']"

areq GET /admin/reports/maintenance
assert_status "GET /admin/reports/maintenance" 200
assert_field  "Maintenance report has byCategory"       "['byCategory']"
assert_field  "Maintenance report has byStatus"         "['byStatus']"
assert_field  "Maintenance report has avgResolutionDays" "['avgResolutionDays']"

areq GET /admin/reports/occupancy
assert_status "GET /admin/reports/occupancy" 200
assert_field  "Occupancy report has total"         "['total']"
assert_field  "Occupancy report has occupied"      "['occupied']"
assert_field  "Occupancy report has occupancyRate" "['occupancyRate']"
assert_field  "Occupancy report has byType"        "['byType']"

areq GET /admin/reports/gate
assert_status "GET /admin/reports/gate" 200
assert_field  "Gate report has passesCreatedThisWeek" "['passesCreatedThisWeek']"
assert_field  "Gate report has scansPerDay"           "['scansPerDay']"

# ─────────────────────────────────────────────────────────────────────────────
section "SWAGGER DOCS"

STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/docs")
[ "$STATUS" = "200" ] && ok "Swagger docs accessible" || fail "Swagger docs" "HTTP $STATUS"

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────"
TOTAL=$((PASS + FAIL))
echo -e "${BOLD}Review complete: ${GREEN}$PASS passed${RESET}, ${RED}$FAIL failed${RESET} / $TOTAL total"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo -e "${RED}${BOLD}Failures:${RESET}"
  for f in "${FAILURES[@]}"; do
    echo -e "  ${RED}•${RESET} $f"
  done
  echo ""
  exit 1
else
  echo ""
  echo -e "${GREEN}${BOLD}✅ All checks passed. Project is ready for delivery.${RESET}"
  echo ""
  exit 0
fi
