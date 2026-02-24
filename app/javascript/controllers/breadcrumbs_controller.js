import { Controller } from "@hotwired/stimulus"

const MAX_BREADCRUMBS = 4
const STORAGE_KEY = "breadcrumb_trail"

// Connects to data-controller="breadcrumbs"
export default class extends Controller {
  static targets = ["list"]

  connect() {
    this.render()
  }

  render() {
    const trail = this.#buildTrail()
    this.#saveTrail(trail)

    if (trail.length === 0) {
      this.element.style.display = "none"
      return
    }

    const breadcrumbs = this.#buildBreadcrumbs(trail)
    this.listTarget.innerHTML = breadcrumbs
  }

  #buildTrail() {
    const meta = document.querySelector('meta[name="breadcrumb"]')
    if (!meta) return

    const name = meta.content
    const url = window.location.pathname

    let trail = this.#getPreviousTrail()

    // Remove duplicates
    trail = trail.filter(item => item.url !== url)

    // Add current page
    trail.push({ name, url })

    // Keep only last MAX_BREADCRUMBS
    trail = trail.slice(-MAX_BREADCRUMBS)

    return trail
  }

  #getPreviousTrail() {
    return JSON.parse(sessionStorage.getItem(STORAGE_KEY) || "[]")
  }

  #saveTrail(trail) {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(trail))
  }

  #buildBreadcrumbs(trail) {
    const separator = '<span class="breadcrumb-separator" aria-hidden="true">↦</span>'

    return trail.map((item, index) => {
      const isLast = index === trail.length - 1

      if (isLast) {
        // Current page is not a link
        return `<li class="breadcrumb-current">${this.#escapeHtml(item.name)}</li>`
      } else {
        const opacity = this.#calculateOpacity(index, trail.length)
        return `
        <li style="opacity: ${opacity}">
          <a href="${this.#escapeHtml(item.url)}">${this.#escapeHtml(item.name)}</a>
        </li>
        `
      }
    }).join(separator)
  }

  // Calculate opacity based on position in trail
  // Current page = 100%, previous = 80%, etc.
  #calculateOpacity(index, totalLength) {
    // Position from the end (0 = current, 1 = previous, etc.)
    const positionFromEnd = totalLength - 1 - index
    const opacity = 1 - (positionFromEnd * 0.2)
    return Math.max(0.4, opacity)
  }

  // Escape HTML to prevent XSS
  #escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
