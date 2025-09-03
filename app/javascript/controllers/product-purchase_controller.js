import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "add", "remove"];

  formContent = "";

  restoreState = () => {
    const savedFormContent = localStorage.getItem("savedFormContent");
    if (savedFormContent) {
      this.formContent = savedFormContent;
      this.enableVisibleMode();
    } else {
      this.enableHiddenMode();
    }
  };

  saveState = () => {
    localStorage.setItem("savedFormContent", this.formTarget.innerHTML);
  };

  connect() {
    console.log("connect");
    this.formContent = this.formTarget.innerHTML;
    this.enableHiddenMode();
    document.addEventListener("turbo:submit-start", this.saveState);
    document.addEventListener("turbo:submit-end", this.restoreState);
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.saveState);
    document.removeEventListener("turbo:submit-end", this.restoreState);
    localStorage.removeItem("savedFormContent");
    this.formContent = "";
  }

  addForm(event) {
    event.preventDefault();
    this.enableVisibleMode();
  }

  removeForm(event) {
    event.preventDefault();
    this.formContent = this.formTarget.innerHTML;
    this.enableHiddenMode();
  }

  enableHiddenMode() {
    // Hide form
    this.formTarget.innerHTML = "";
    // Show "add" button
    this.addTarget.classList.remove("hidden");
    // Hide "cancel" button
    this.removeTarget.classList.add("hidden");
  }

  enableVisibleMode() {
    // Show form
    this.formTarget.innerHTML = this.formContent;
    // Show "cancel" button
    this.removeTarget.classList.remove("hidden");
    // Hide "add" button
    this.addTarget.classList.add("hidden");
  }
}
