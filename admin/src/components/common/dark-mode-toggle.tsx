import { useState, useEffect } from 'react'
import { Moon, Sun } from 'lucide-react'
import { Button } from '@/components/ui/button'

export function DarkModeToggle() {
  const [dark, setDark] = useState(() => {
    if (typeof window === 'undefined') return false
    return document.documentElement.classList.contains('dark')
  })

  useEffect(() => {
    if (dark) {
      document.documentElement.classList.add('dark')
      localStorage.setItem('alsafa_theme', 'dark')
    } else {
      document.documentElement.classList.remove('dark')
      localStorage.setItem('alsafa_theme', 'light')
    }
  }, [dark])

  // Load saved preference
  useEffect(() => {
    const saved = localStorage.getItem('alsafa_theme')
    if (saved === 'dark') {
      setDark(true)
      document.documentElement.classList.add('dark')
    }
  }, [])

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => setDark((d) => !d)}
      title={dark ? 'Switch to light mode' : 'Switch to dark mode'}
    >
      {dark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
    </Button>
  )
}
