import { Controller } from "@hotwired/stimulus";

export default class Removable extends Controller {
  static targets = ["element"];

  removedEvent = null;

  disconnect() {
    removeEventListener("animationend", removedEvent);
  }

  remove(event) {
    const imageContainer = event.target.parentElement;
    imageContainer.classList.add("removed");
    this.removedEvent = imageContainer.addEventListener("animationend", () => {
      imageContainer.remove();
    });
  }
}
