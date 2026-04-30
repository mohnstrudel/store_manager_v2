import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = [ "variants" ]
  static values = {
    path: String,
  }

  change(event) {
    const productId = event.currentTarget.value
    if (!productId) return this.clearVariants()

    get(this.requestPath(productId), {
      responseKind: "turbo-stream",
    }).catch((error) => {
      console.error("Failed to load purchase variants:", error)
    })
  }

  clearVariants() {
    this.variantsTarget.innerHTML = ""
  }

  requestPath(productId) {
    const params = new URLSearchParams({
      product_id: productId,
      target: this.variantsTarget.id,
    })

    return `${this.pathValue}?${params.toString()}`
  }
}
