import { Controller } from "@hotwired/stimulus"

// Envoie le formulaire quand on appuie sur Entrée dans le champ de saisie.
// Maj + Entrée insère un retour à la ligne.
export default class extends Controller {
  submit(event) {
    if (event.key !== "Enter" || event.shiftKey || event.isComposing) return

    event.preventDefault()
    if (this.element.value.trim() === "") return

    this.element.form.requestSubmit()
  }
}
