import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];

  open(e) {
    e.preventDefault();
    e.currentTarget.blur();
    this.dispatch("open");
  }
}
