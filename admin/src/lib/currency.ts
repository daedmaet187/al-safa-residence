// Currency store — persists to localStorage
const CURRENCY_KEY = 'alsafa_currency'

export const CURRENCIES = [
  { code: 'IQD', label: 'Iraqi Dinar (IQD)' },
  { code: 'USD', label: 'US Dollar (USD)' },
  { code: 'EUR', label: 'Euro (EUR)' },
  { code: 'AED', label: 'UAE Dirham (AED)' },
  { code: 'SAR', label: 'Saudi Riyal (SAR)' },
]

export function getCurrency(): string {
  if (typeof window === 'undefined') return 'IQD'
  return localStorage.getItem(CURRENCY_KEY) ?? 'IQD'
}

export function setCurrency(code: string) {
  localStorage.setItem(CURRENCY_KEY, code)
  window.dispatchEvent(new Event('currency-change'))
}
