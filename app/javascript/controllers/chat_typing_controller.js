import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Filet de sécurité : si la réponse n'est toujours pas arrivée après 20 s
// (direct déconnecté, réponse envoyée avant que la page soit abonnée…), on recharge la page.
// Le brouillon du champ de saisie est conservé (data-turbo-permanent).
const RELOAD_AFTER_MS = 20_000

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => Turbo.visit(window.location.href, { action: "replace" }), RELOAD_AFTER_MS)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
