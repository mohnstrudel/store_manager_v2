import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slide", "main"];

  nextImage = null;

  initialize() {
    this.selectedImgIndex = 0;
    this.showCurrentSlide();
  }

  select(event) {
    event.preventDefault();
    let newSelectedImgIndex = Number(event.target.dataset.id);
    if (this.selectedImgIndex === newSelectedImgIndex) return;
    this.selectedImgIndex = newSelectedImgIndex;
    this.showCurrentSlide();
    this.changeImage(event.target.dataset.preview);
  }

  changeImage(imageSrc) {
    this.mainTarget.src =
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
    this.nextImage = new Image();
    this.nextImage.onload = () => {
      this.mainTarget.src = this.nextImage.src;
    };
    this.nextImage.onerror = () => {
      this.mainTarget.src = "";
    };
    this.nextImage.fetchPriority = "high";
    this.nextImage.src = imageSrc;
  }

  next() {
    if (this.selectedImgIndex + 1 >= this.slideTargets.length) {
      this.selectedImgIndex = 0;
    } else {
      this.selectedImgIndex++;
    }
    this.showCurrentSlide();
    this.changeImage(this.slideTargets[this.selectedImgIndex].dataset.preview);
  }

  prev() {
    if (this.selectedImgIndex - 1 < 0) {
      this.selectedImgIndex = this.slideTargets.length - 1;
    } else {
      this.selectedImgIndex--;
    }
    this.showCurrentSlide();
    this.changeImage(this.slideTargets[this.selectedImgIndex].dataset.preview);
  }

  showCurrentSlide() {
    this.slideTargets.forEach((element, index) => {
      if (index === this.selectedImgIndex) {
        element.classList.add("active");
        element.scrollIntoView({
          behavior: "smooth",
          block: "nearest",
          inline: "start",
        });
      } else {
        element.classList.remove("active");
      }
    });
  }
}
