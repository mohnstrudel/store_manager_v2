import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="payment"
export default class extends Controller {
  clear() {
    this.element.querySelector("#payment_amount").value = "";
  }
}
