import { Controller } from "@hotwired/stimulus"

// Garde le dernier message visible : défile en bas à l'ouverture et à chaque nouveau message (Turbo Streams)
export default class extends Controller {
  connect() {
    this.observer = new MutationObserver(() => this.scrollToBottom())
    this.observer.observe(this.element, { childList: true, subtree: true })
    this.scrollToBottom()
  }

  disconnect() {
    this.observer.disconnect()
  }

  scrollToBottom() {
    this.element.lastElementChild?.scrollIntoView({ block: "end", behavior: "smooth" })
  }
}
