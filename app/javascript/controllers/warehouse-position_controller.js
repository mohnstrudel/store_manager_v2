import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["positionSelect"];

  changePosition(event) {
    const select = event.currentTarget;
    const warehouseId = select.dataset.warehouseId;
    const newPosition = select.value;

    // Create the form to trigger a request
    const form = document.createElement("form");
    form.method = "POST";
    form.action = `/warehouses/${warehouseId}/change_position`;

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    const csrfInput = document.createElement("input");
    csrfInput.type = "hidden";
    csrfInput.name = "authenticity_token";
    csrfInput.value = csrfToken;

    // Add position parameter
    const positionInput = document.createElement("input");
    positionInput.type = "hidden";
    positionInput.name = "position";
    positionInput.value = newPosition;

    form.appendChild(csrfInput);
    form.appendChild(positionInput);

    document.body.appendChild(form);
    form.submit();
  }
}
