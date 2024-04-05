import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  static targets = ["select"];

  change(event) {
    let productId = event.target.selectedOptions[0].value;
    let target = this.selectTarget.id;

    get(`/products/${productId}/variations?target=${target}`, {
      responseKind: "turbo-stream",
    });
  }
}
