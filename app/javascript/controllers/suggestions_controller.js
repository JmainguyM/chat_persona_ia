import { Controller } from "@hotwired/stimulus"

// Propositions de messages : un clic remplit le champ de saisie,
// l'utilisateur peut encore modifier le texte avant d'envoyer.
export default class extends Controller {
  static targets = ["input"]

  use(event) {
    const input = this.inputTarget
    input.value = event.currentTarget.dataset.suggestion
    input.focus()
    input.setSelectionRange(input.value.length, input.value.length)
  }
}
