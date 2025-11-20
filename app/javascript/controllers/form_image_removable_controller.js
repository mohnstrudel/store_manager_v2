import { Controller } from "stimulus";
import { useClickOutside } from 'stimulus-use'

export default class extends Controller {
  static targets = ["image", "button", "hiddenInput"];

  connect() {
    useClickOutside(this)
    this.isRemoved = false;
    this.originalButtonContent = this.buttonTarget.innerHTML;
    this.isImageScaled = false;
  }

  clickOutside() {
    if (this.isRemoved) return;
    if (this.isImageScaled) this.toggleImageScale();
  }

  remove(event) {
    event.preventDefault();

    if (!this.isRemoved) {
      this.isRemoved = true;

      // Make the image look like it was "removed"
      this.imageTarget.classList.remove("cursor-zoom-in");
      this.imageTarget.classList.add("opacity-50", "cursor-not-none", "saturate-40");

      // To be able to undo
      this.storedHiddenInput = this.hiddenInputTarget.cloneNode(true);

      this.hiddenInputTarget.remove();

      this.buttonTarget.innerHTML = "Undo";
      this.buttonTarget.classList.remove("btn-red");
      this.buttonTarget.title = "Undo removal";
    } else {
      // Undo removal
      this.isRemoved = false;

      this.imageTarget.classList.remove("opacity-50", "cursor-not-none", "saturate-40");
      this.imageTarget.classList.add("cursor-zoom-in");

      this.element.appendChild(this.storedHiddenInput);

      this.buttonTarget.innerHTML = this.originalButtonContent;
      this.buttonTarget.classList.add("btn-red");
      this.buttonTarget.title = "Remove";
    }
  }

  toggleImageScale() {
    if (this.isRemoved) return;

    if (this.isImageScaled) {
      this.imageTarget.classList.remove("scale-300", "z-10", "cursor-zoom-out", "-translate-y-1/2", "left-1/2", "shadow-xl");
      this.imageTarget.classList.add("z-0", "cursor-zoom-in");
      this.isImageScaled = false;
    } else {
      this.imageTarget.classList.remove("z-0", "cursor-zoom-in");
      this.imageTarget.classList.add("scale-300", "z-10", "cursor-zoom-out", "-translate-y-1/2", "left-1/2", "shadow-xl");
      this.isImageScaled = true;
    }
  }
}
