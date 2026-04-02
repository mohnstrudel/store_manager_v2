import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "template", "add"];
  static values = { expanded: Boolean };

  connect() {
    this.expandedValue ? this.show() : this.hide()
  }

  addForm(event) {
    event.preventDefault();
    this.show();
  }

  removeForm(event) {
    event.preventDefault();
    this.hide();
  }

  show() {
    if (this.formTarget.innerHTML.trim() === "") {
      this.formTarget.innerHTML = this.templateTarget.innerHTML;
    }

    this.addTarget.classList.add("hidden");
  }

  hide() {
    this.formTarget.innerHTML = "";
    this.addTarget.classList.remove("hidden");
  }
}
