import { useEffect, useState } from "react"

export const useTypewriter = (text: string, speed = 40) => {
  const [display, setDisplay] = useState("")

  useEffect(() => {
    let index = 0

    const interval = setInterval(() => {
      setDisplay(text.slice(0, index))
      index += 1

      if (index > text.length) {
        clearInterval(interval)
      }
    }, speed)

    return () => clearInterval(interval)
  }, [text, speed])

  return display
}
