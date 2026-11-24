import { Controller } from "@hotwired/stimulus"

// Aperçu en direct de la carte persona pendant la saisie du formulaire,
// et exemples de system prompt insérables en un clic.
export default class extends Controller {
  static targets = ["nameInput", "descriptionInput", "promptInput", "avatarInput", "name", "description", "avatar"]

  update() {
    const name = this.nameInputTarget.value.trim()
    const description = this.descriptionInputTarget.value.trim()

    this.nameTarget.textContent = name || "Your persona"
    this.descriptionTarget.textContent = description || "Its short description will appear here."
    this.renderAvatar(name)
  }

  useStarter(event) {
    const prompt = this.promptInputTarget
    if (prompt.value.trim() !== "" && !prompt.dataset.fromStarter) return this.flash(prompt)

    prompt.value = event.currentTarget.dataset.prompt
    prompt.dataset.fromStarter = "true"
    prompt.addEventListener("input", () => delete prompt.dataset.fromStarter, { once: true })
    prompt.focus()
  }

  // Ne remplace pas un prompt déjà écrit par l'utilisateur : on le signale juste
  flash(element) {
    element.classList.add("persona-flash")
    setTimeout(() => element.classList.remove("persona-flash"), 600)
  }

  renderAvatar(name) {
    const url = this.avatarInputTarget.value.trim()
    const frame = this.avatarTarget

    if (/^https?:\/\/\S+$/.test(url)) {
      const img = document.createElement("img")
      img.className = "dash-persona-img"
      img.alt = name
      img.src = url
      img.addEventListener("error", () => frame.replaceChildren(this.initials(name)), { once: true })
      frame.replaceChildren(img)
    } else {
      frame.replaceChildren(this.initials(name))
    }
  }

  initials(name) {
    const div = document.createElement("div")
    div.className = "dash-persona-img persona-initials"
    div.setAttribute("aria-hidden", "true")
    div.textContent = name.split(/\s+/).filter(Boolean).slice(0, 2).map((word) => word[0]).join("").toUpperCase() || "?"
    return div
  }
}
