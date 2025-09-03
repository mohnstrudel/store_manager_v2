import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "count",
    "checkbox",
    "destination",
    "toggleAllLink",
    "form",
  ];

  haveCheckboxes;
  prevCheckedCount = 0;

  connect() {
    this.haveCheckboxes = this.checkboxTargets.length > 0;
    this.updateCountLabel();
  }

  move(e) {
    e.preventDefault();

    const form = this.formTarget;
    const destinationId = this.destinationTarget.value;

    const selectedIds = this.checkboxTargets
      .filter((checkbox) => checkbox.checked)
      .map((checkbox) => checkbox.value);

    selectedIds.forEach((id) => {
      const hiddenField = document.createElement("input");
      hiddenField.type = "hidden";
      hiddenField.name = "selected_items_ids[]";
      hiddenField.value = id;
      form.appendChild(hiddenField);
    });

    if (!this.haveCheckboxes || selectedIds.length > 0) {
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

  toggleFormVisibility() {
    const form = this.element.querySelector(".move_to_warehouse__form");

    if (!this.haveCheckboxes) return form.classList.toggle("hidden");

    const prevCount = this.prevCheckedCount;
    const nextCount = this.getCheckedCount();

    this.updateCountLabel(nextCount);

    if (nextCount === 0 || (prevCount === 0 && nextCount > 0)) {
      form.classList.toggle("hidden");
    }
    this.prevCheckedCount = nextCount;
  }

  getCheckedCount() {
    return this.checkboxTargets.filter((checkbox) => checkbox.checked).length;
  }

  updateCountLabel(count) {
    count = this.getCheckedCount();
    if (count === 0) {
      this.countTarget.textContent = "";
    } else {
      let text = count === 1 ? "item" : "items";
      this.countTarget.textContent = `${count} ${text}`;
    }
  }

  toggleCheckboxes(checked) {
    this.checkboxTargets.forEach((checkbox) => (checkbox.checked = checked));
  }

  toggleMassSelect(event) {
    event.preventDefault();
    const link = this.toggleAllLinkTarget;
    const isSelecting = link.textContent === "Move";

    this.toggleCheckboxes(isSelecting);

    if (isSelecting) {
      link.textContent = "Undo";
      link.classList.toggle("undo");
    } else {
      link.textContent = "Move";
      link.classList.toggle("undo");
    }

    this.toggleFormVisibility();
  }
}
