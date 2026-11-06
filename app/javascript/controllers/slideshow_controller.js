import { Controller } from "@hotwired/stimulus"

// Banner slideshow: slides the photos sideways every few seconds. It holds still
// while the pointer or keyboard focus is in the banner (so it doesn't move while
// someone uses the filters), and doesn't move at all for people who prefer
// reduced motion.
export default class extends Controller {
  static targets = ["track"]
  static values = { interval: { type: Number, default: 6000 } }

  connect() {
    this.index = 0
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.start()
  }

  disconnect() {
    this.stop()
  }

  start() {
    if (this.reducedMotion || this.count < 2) return
    this.stop()
    this.timer = setInterval(() => this.next(), this.intervalValue)
  }

  stop() {
    clearInterval(this.timer)
  }

  next() {
    this.index = (this.index + 1) % this.count
    this.trackTarget.style.transform = `translateX(-${this.index * 100}%)`
  }

  get count() {
    return this.trackTarget.children.length
  }
}
