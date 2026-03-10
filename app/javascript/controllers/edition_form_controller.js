import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]
  static values = { index: Number }

  connect() {
    // Count all existing edition fields (both in grid and in container)
    const existingEditions = document.querySelectorAll(".edition-fields").length
    this.indexValue = existingEditions
  }

  add() {
    const content = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, this.indexValue++)
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(e) {
    e.preventDefault()
    const field = e.target.closest(".edition-fields")
    field.remove()
  }
}
