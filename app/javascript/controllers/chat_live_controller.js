import { Controller } from "@hotwired/stimulus"

// Garde le dernier message visible : défile en bas à l'ouverture et à chaque nouveau message (Turbo Streams).
// Repère aussi les messages des autres participants : le HTML diffusé est le même pour tout le monde,
// donc seul le navigateur sait qui est "moi".
export default class extends Controller {
  static values = { currentUserId: Number }

  connect() {
    this.observer = new MutationObserver(() => this.refresh())
    this.observer.observe(this.element, { childList: true, subtree: true })
    this.refresh()
  }

  disconnect() {
    this.observer.disconnect()
  }

  refresh() {
    this.markOthersMessages()
    this.scrollToBottom()
  }

  // Les anciens messages n'ont pas d'auteur (pas de data-author-id) : ils restent les nôtres
  markOthersMessages() {
    this.element.querySelectorAll(".chat-message-user[data-author-id]").forEach((message) => {
      const isMine = Number(message.dataset.authorId) === this.currentUserIdValue
      message.classList.toggle("chat-message-other", !isMine)
    })
  }

  scrollToBottom() {
    this.element.lastElementChild?.scrollIntoView({ block: "end", behavior: "smooth" })
  }
}
