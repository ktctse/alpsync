import { Controller } from "@hotwired/stimulus"

// Banner slideshow: slides the photos sideways every few seconds, with numbered
// buttons to jump to one. It holds still while the pointer or keyboard focus is
// in the banner (so it doesn't move while someone uses the filters), and doesn't
// auto-advance at all for people who prefer reduced motion.
export default class extends Controller {
  static targets = ["track", "button", "caption"]
  static values = { interval: { type: Number, default: 6000 } }

  connect() {
    this.index = 0
    this.reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    if (this.reducedMotion) this.trackTarget.style.transition = "none"
    this.render()
    this.start()
  }

  disconnect() {
    this.stop()
  }

  start() {
    if (this.reducedMotion || this.buttonTargets.length < 2) return
    this.stop()
    this.timer = setInterval(() => this.show((this.index + 1) % this.buttonTargets.length), this.intervalValue)
  }

  stop() {
    clearInterval(this.timer)
  }

  select(event) {
    this.show(Number(event.currentTarget.dataset.index))
  }

  show(index) {
    this.index = index
    this.render()
  }

  render() {
    this.trackTarget.style.transform = `translateX(-${this.index * 100}%)`
    this.buttonTargets.forEach((button, i) => button.setAttribute("aria-current", i === this.index))
    this.captionTarget.textContent = this.buttonTargets[this.index].dataset.caption
  }
}
