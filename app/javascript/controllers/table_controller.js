import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  goTo(event) {
    if (this.shouldIgnoreClick(event)) return

    event.preventDefault()

    const url = this.destinationUrl(event.params)

    if (event.metaKey || event.ctrlKey) {
      this.openInNewTab(url)
      return
    }

    window.location.assign(url)
  }

  shouldIgnoreClick(event) {
    return Boolean(
      event.target.closest(".actions") ||
      event.target.closest(".no-events")
    )
  }

  destinationUrl(params) {
    const url = new URL(params.url, window.location.origin)
    if (!params.id) return url.toString()

    url.searchParams.set("selected", params.id)
    url.hash = params.id

    return url.toString()
  }

  openInNewTab(url) {
    window.open(url, "_blank")
  }
}
