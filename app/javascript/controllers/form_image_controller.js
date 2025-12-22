import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["container", "image", "removeButton", "hiddenInput", "fileField", "replaceButton", "replaceLabel"];

  connect() {
    this.isRemoved = false;
    this.isReplacing = false;
    this.removeButtonTargetOriginalContent = this.removeButtonTarget.innerHTML;
  }

  remove(event) {
    event.preventDefault();

    if (!this.isRemoved) {
      this.isRemoved = true;

      // Make the image look like it was "removed"
      this.imageTarget.classList.add("opacity-50", "saturate-40");
      this.containerTarget.classList.add("rectangle-with-x");

      // Set _destroy to 1 to mark for deletion
      this.hiddenInputTarget.value = "1";

      this.removeButtonTarget.textContent = "Keep";
      this.removeButtonTarget.classList.remove("btn-red");
      this.removeButtonTarget.classList.add("btn-green");
      this.removeButtonTarget.title = "Undo removal";
    } else {
      this.isRemoved = false;

      this.imageTarget.classList.remove("opacity-50", "saturate-40");
      this.containerTarget.classList.remove("rectangle-with-x");

      // Set _destroy back to 0 to keep
      this.hiddenInputTarget.value = "0";

      this.removeButtonTarget.innerHTML = this.removeButtonTargetOriginalContent;
      this.removeButtonTarget.classList.remove("btn-green");
      this.removeButtonTarget.classList.add("btn-red");
      this.removeButtonTarget.title = "Remove";
    }
  }

  replace(event) {
    event.preventDefault();

    if (!this.isReplacing) {
      this.isReplacing = true;

      this.fileFieldTarget.classList.remove("hidden");

      this.replaceLabelTarget.innerHTML = "Undo";
      this.replaceButtonTarget.title = "Undo replacement";
    } else {
      this.isReplacing = false;

      this.fileFieldTarget.classList.add("hidden");
      this.fileFieldTarget.value = "";

      this.replaceLabelTarget.innerHTML = "Replace";
      this.replaceButtonTarget.title = "Replace";
    }
  }
}
