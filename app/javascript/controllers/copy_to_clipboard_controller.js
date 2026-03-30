import { Controller } from "@hotwired/stimulus";

export default class CopyToClipboard extends Controller {
  static values = {
    text: String,
    duration: { type: Number, default: 800 },
  };

  static targets = ["icon", "text"];

  connect() {
    this.defaultText = this.hasTextTarget ? this.textTarget.textContent : null;
    this.resetContent();
  }

  copy() {
    if (!this.textValue) return;

    navigator.clipboard
      .writeText(this.textValue)
      .then(() => {
        this.showSuccessContent();
        setTimeout(() => {
          this.resetContent();
        }, this.durationValue);
      })
      .catch((err) => {
        console.error("Failed to copy text: ", err);
      });
  }

  showSuccessContent() {
    this.targets.element.classList.add("btn-amber");
    if (this.hasIconTarget) {
      this.iconTarget.textContent = "👍";
    }
    if (this.hasTextTarget) {
      this.textTarget.textContent = "Done";
    }
  }

  resetContent() {
    this.targets.element.classList.remove("btn-amber");
    if (this.hasIconTarget) {
      this.iconTarget.textContent = "📋";
    }
    if (this.hasTextTarget) {
      this.textTarget.textContent = this.defaultText || "Copy";
    }
  }
}
