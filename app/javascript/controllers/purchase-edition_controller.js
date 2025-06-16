import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  static targets = ["select"];

  change(event) {
    let productId = event.target.selectedOptions[0].value;
    let target = this.selectTarget.id;
    let queryPath = `?product_id=${productId}&target=${target}`;

    get(`/purchases/product_editions${queryPath}`, {
      responseKind: "turbo-stream",
    }).catch((error) => console.error("Failed to load editions:", error));
  }
}
