import { Controller } from "@hotwired/stimulus"

// Notification flash : se ferme quand sa barre de progression arrive au bout
// (animation CSS, en pause au survol) ou au clic sur la croix.
export default class extends Controller {
  dismissAfterProgress(event) {
    if (event.target.classList.contains("flash-progress")) this.dismiss()
  }

  dismiss() {
    if (this.element.classList.contains("flash-leaving")) return

    this.element.classList.add("flash-leaving")
    // Retire l'élément après l'animation de sortie (immédiatement si les animations sont désactivées)
    const remove = () => this.element.remove()
    this.element.addEventListener("animationend", remove, { once: true })
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) remove()
  }
}
