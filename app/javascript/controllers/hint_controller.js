import { Controller } from "@hotwired/stimulus"

// Lets a hover hint open on click or tap too. Hover alone isn't enough:
// phones have no hover, and Safari doesn't focus a button when it's clicked.
// The open state is a data-open attribute that the CSS shows the hint for.
export default class extends Controller {
  static targets = ["button"]

  toggle() {
    this.setOpen(!this.element.hasAttribute("data-open"))
  }

  closeOutside(event) {
    if (!this.element.contains(event.target)) this.setOpen(false)
  }

  close() {
    this.setOpen(false)
  }

  setOpen(open) {
    this.element.toggleAttribute("data-open", open)
    this.buttonTarget.setAttribute("aria-expanded", String(open))
  }
}
