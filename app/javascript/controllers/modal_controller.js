import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];

  triggerEvent = null;
  triggerEventName = "modal-trigger:open";

  connect() {
    this.triggerEvent = addEventListener(this.triggerEventName, (e) =>
      this.open(e),
    );
  }

  disconnect() {
    removeEventListener(this.triggerEventName, this.triggerEvent);
  }

  open(e) {
    e.preventDefault();
    this.containerTarget.showModal();
  }

  close(e) {
    e.preventDefault();
    this.containerTarget.close();
  }
}
