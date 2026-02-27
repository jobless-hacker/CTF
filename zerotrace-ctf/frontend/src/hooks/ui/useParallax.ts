import { useEffect } from "react"
import type { RefObject } from "react"

export const useParallax = (ref: RefObject<HTMLDivElement | null>) => {
  useEffect(() => {
    const handleMove = (event: MouseEvent) => {
      if (!ref.current) {
        return
      }

      const x = (window.innerWidth / 2 - event.clientX) / 50
      const y = (window.innerHeight / 2 - event.clientY) / 50
      ref.current.style.transform = `rotateY(${x}deg) rotateX(${y}deg)`
    }

    window.addEventListener("mousemove", handleMove)
    return () => window.removeEventListener("mousemove", handleMove)
  }, [ref])
}
