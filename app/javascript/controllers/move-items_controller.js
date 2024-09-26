import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "count",
    "checkbox",
    "destination",
    "toggleAllLink",
    "form",
  ];

  connect() {
    this.updateCount();
  }

  updateSelection() {
    this.updateCount();
    this.toggleFloatingBox();
  }

  selectAll() {
    this.checkboxTargets.forEach((checkbox) => (checkbox.checked = true));
    this.updateCount();
  }

  move(e) {
    e.preventDefault();

    const form = this.formTarget;

    const selectedIds = this.checkboxTargets
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.value);

    const destinationId = this.destinationTarget.value;

    selectedIds.forEach((id) => {
      const hiddenField = document.createElement("input");
      hiddenField.type = "hidden";
      hiddenField.name = "selected_items_ids[]";
      hiddenField.value = id;
      form.appendChild(hiddenField);
    });

    if (selectedIds.length > 0) {
      if (destinationId) {
        form.submit();
      } else {
        const selectElement = document.querySelector(".ss-main");
        selectElement.focus();
        selectElement.classList.add("has-error");
        setTimeout(() => {
          selectElement.classList.remove("has-error");
        }, 2000);
      }
    }
  }

  updateCount() {
    const count = this.checkboxTargets.filter(
      (checkbox) => checkbox.checked,
    ).length;
    let text = count === 1 ? "item" : "items";
    this.countTarget.textContent = `${count} ${text}`;
  }

  toggleFloatingBox() {
    const container = this.element.querySelector(".move_to_warehouse__form");
    container.classList.toggle(
      "hidden",
      this.checkboxTargets.every((checkbox) => !checkbox.checked),
    );
  }

  toggleAll(event) {
    event.preventDefault();
    const link = this.toggleAllLinkTarget;
    const isSelecting = link.textContent === "Select";

    this.checkboxTargets.forEach(
      (checkbox) => (checkbox.checked = isSelecting),
    );

    if (isSelecting) {
      link.textContent = "Undo";
      link.classList.toggle("undo");
    } else {
      link.textContent = "Select";
      link.classList.toggle("undo");
    }

    this.updateCount();
    this.toggleFloatingBox();
  }
}
