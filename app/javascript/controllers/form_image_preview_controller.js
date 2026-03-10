import { Controller } from "stimulus";

export default class extends Controller {
  static targets = ["input", "container", "image", "button"];

  generate() {
    Array.from(this.inputTarget.files).forEach((file, index) => {
      const container = this.buildContainer();
      const button = this.buildButton();
      const img = this.buildImage();

      button.onclick = () => this.remove(container, index);
      img.src = URL.createObjectURL(file);

      container.appendChild(img);
      container.appendChild(button);

      this.containerTarget.appendChild(container);
    });
  }

  buildContainer() {
    const imgContainer = document.createElement("div");
    imgContainer.className = "text-center mt-4";
    return imgContainer;
  }

  buildButton() {
    const button = this.buttonTarget.cloneNode(true);
    button.classList.remove("hidden");
    return button;
  }

  buildImage() {
    const img = document.createElement("img");
    img.className = "w-40 h-auto rounded-sm border border-gray-200 dark:border-gray-700 shadow-none";
    return img;
  }

  remove(imgContainer, index) {
    const dt = new DataTransfer();

    Array.from(this.inputTarget.files).forEach((file, idx) => {
      if (idx === index) {
        imgContainer.remove();
      } else {
        dt.items.add(file);
      }
    });

    this.inputTarget.files = dt.files;
  }
}
