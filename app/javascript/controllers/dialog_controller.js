import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog" ]

  static values = {
    autoOpen: { type: Boolean, default: false },
    modal: { type: Boolean, default: true },
  }

  connect() {
    this.dialogTarget.setAttribute("aria-hidden", "true")
    if (this.autoOpenValue) this.open()
  }

  open(event) {
    event?.preventDefault()
    event?.currentTarget?.blur()

    if (this.modalValue) {
      this.dialogTarget.showModal()
    } else {
      this.dialogTarget.show()
    }

    this.dialogTarget.setAttribute("aria-hidden", "false")
    this.loadLazyFrames()
    this.dispatch("show")
  }

  toggle(event) {
    event?.preventDefault()

    if (this.dialogTarget.open) {
      this.close()
    } else {
      this.open()
    }
  }

  close(event) {
    event?.preventDefault()
    if (!this.dialogTarget.open) return

    this.dialogTarget.close()
    this.dialogTarget.setAttribute("aria-hidden", "true")
    this.dialogTarget.blur()
    this.dispatch("close")
  }

  closeOnClickOutside({ target }) {
    if (!this.dialogTarget.open) return
    if (this.element.contains(target)) return

    this.close()
  }

  closeAndSubmit(event) {
    event.preventDefault()
    this.close()
    event.currentTarget.form?.requestSubmit()
  }

  loadLazyFrames() {
    this.dialogTarget.querySelectorAll("turbo-frame").forEach((frame) => {
      frame.loading = "eager"
    })
  }
}
