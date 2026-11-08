import { Controller } from "@hotwired/stimulus"

// Marks the viewer's own chat messages and keeps the newest one in view.
// Messages are rendered the same for both riders (they're broadcast to both),
// so which ones are "mine" is decided here, in the browser.
export default class extends Controller {
  static values = { me: Number }

  connect() {
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.element, { childList: true })
    this.refresh()
  }

  disconnect() {
    this.observer.disconnect()
  }

  refresh() {
    const messages = this.element.querySelectorAll("[data-sender]")
    for (const message of messages) {
      message.classList.toggle("mine", Number(message.dataset.sender) === this.meValue)
    }
    document.getElementById("chat_hint")?.toggleAttribute("hidden", messages.length > 0)
    this.element.lastElementChild?.scrollIntoView({ block: "nearest" })
  }
}
