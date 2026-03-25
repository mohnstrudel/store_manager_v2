import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = [ "editions" ]
  static values = {
    path: String,
  }

  change(event) {
    const productId = event.currentTarget.value
    if (!productId) return this.clearEditions()

    get(this.requestPath(productId), {
      responseKind: "turbo-stream",
    }).catch((error) => {
      console.error("Failed to load purchase editions:", error)
    })
  }

  clearEditions() {
    this.editionsTarget.innerHTML = ""
  }

  requestPath(productId) {
    const params = new URLSearchParams({
      product_id: productId,
      target: this.editionsTarget.id,
    })

    return `${this.pathValue}?${params.toString()}`
  }
}
