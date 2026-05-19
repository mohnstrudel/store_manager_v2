import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  show(event) {
    const panelName = event.currentTarget.dataset.tabPanel

    this.tabTargets.forEach(tab => {
      tab.setAttribute("aria-selected", tab.dataset.tabPanel === panelName ? "true" : "false")
    })

    this.panelTargets.forEach(panel => {
      panel.classList.toggle("hidden", panel.dataset.panelName !== panelName)
    })
  }
}
