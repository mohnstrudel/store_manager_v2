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
      responseKind: "json",
    }).then(async (response) => {
      if (!response.ok) throw new Error(`Request failed with status ${response.statusCode}`)

      const body = await response.json
      this.renderVariants(body.variants || [])
    }).catch((error) => {
      console.error("Failed to load purchase variants:", error)
    })
  }

  clearVariants() {
    this.variantsTarget.innerHTML = ""
  }

  renderVariants(variants) {
    this.clearVariants()
    if (variants.length === 0) return

    const label = document.createElement("label")
    label.setAttribute("for", "purchase_variant_id")
    label.textContent = "Variant"

    const select = document.createElement("select")
    select.className = "select"
    select.id = "purchase_variant_id"
    select.name = "purchase[variant_id]"

    select.append(new Option("", ""))
    variants.forEach((variant) => {
      select.append(new Option(variant.title, variant.id))
    })

    this.variantsTarget.append(label, select)
  }

  requestPath(productId) {
    const params = new URLSearchParams({
      product_id: productId,
    })

    return `${this.pathValue}?${params.toString()}`
  }
}
