import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container", "template"];
  static values = { index: Number };

  connect() {
    this.indexValue = this.saleItemFields.length;
  }

  addProduct(event) {
    event.preventDefault();
    this.containerTarget.insertAdjacentHTML("beforeend", this.nextFieldMarkup);
  }

  removeProduct(event) {
    event.preventDefault();

    const field = event.currentTarget.closest(".sales-form__product_fields");
    if (!field) return;

    if (this.isPersistedField(field)) {
      this.markForRemoval(field);
      return;
    }

    field.remove();
  }

  get nextFieldMarkup() {
    return this.templateTarget.innerHTML.replace(/NEW_INDEX/g, this.indexValue++);
  }

  get saleItemFields() {
    return Array.from(this.containerTarget.querySelectorAll(".sales-form__product_fields"));
  }

  isPersistedField(field) {
    return field.querySelector("input[name$='[id]']")?.value?.length > 0;
  }

  markForRemoval(field) {
    const destroyInput = field.querySelector("input[name$='[_destroy]']");
    if (destroyInput) destroyInput.value = "1";

    field.classList.add("hidden");
  }
}
