import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  addTransition(event) {
    event.preventDefault();
    const template = this.element.querySelector("#transition-template");
    const clone = template.content.cloneNode(true);
    template.parentElement.querySelector("tbody").prepend(clone);
  }

  removeTransition(event) {
    event.preventDefault();
    event.target.closest("tr").remove();
  }
}
