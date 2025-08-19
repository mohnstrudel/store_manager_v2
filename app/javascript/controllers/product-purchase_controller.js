import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "add", "remove"];

  formBackup = null;

  connect() {
    const restoreOpenState = window.localStorage.getItem(
      "new-product_purchase-form",
    );
    if (restoreOpenState) {
      this.addTarget.classList.add("hidden");
      this.removeTarget.classList.remove("hidden");
    } else {
      this.formBackup = this.formTarget.outerHTML;
      this.formTarget.remove();
    }
  }

  disconnect() {
    window.localStorage.removeItem("new-product_purchase-form");
  }

  addForm(event) {
    event.preventDefault();
    window.localStorage.setItem("new-product_purchase-form", true);
    this.addTarget.classList.add("hidden");
    this.removeTarget.classList.remove("hidden");
    this.element.insertAdjacentHTML("beforeend", this.formBackup);
  }

  removeForm(event) {
    event.preventDefault();
    window.localStorage.removeItem("new-product_purchase-form");
    this.addTarget.classList.remove("hidden");
    this.removeTarget.classList.add("hidden");
    this.formTarget.remove();
  }
}
