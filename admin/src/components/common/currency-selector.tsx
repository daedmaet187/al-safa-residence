import { useEffect, useState } from 'react'
import { getCurrency, setCurrency, CURRENCIES } from '@/lib/currency'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

export function CurrencySelector() {
  const [currency, setCurrencyState] = useState(getCurrency())

  useEffect(() => {
    const handler = () => setCurrencyState(getCurrency())
    window.addEventListener('currency-change', handler)
    return () => window.removeEventListener('currency-change', handler)
  }, [])

  return (
    <Select
      value={currency}
      onValueChange={(val) => {
        setCurrency(val)
        setCurrencyState(val)
      }}
    >
      <SelectTrigger className="w-[140px] h-8 text-xs">
        <SelectValue />
      </SelectTrigger>
      <SelectContent>
        {CURRENCIES.map((c) => (
          <SelectItem key={c.code} value={c.code} className="text-xs">
            {c.label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
}
