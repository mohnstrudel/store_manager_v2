import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slide", "main"];

  initialize() {
    this.index = 0;
    this.showCurrentSlide();
  }

  select(event) {
    event.preventDefault();
    let container = document.querySelector(".gallery__main");
    // Change navigation
    this.index = Number(event.target.dataset.id);
    this.showCurrentSlide();
    this.changeImage(event.target.dataset.preview);
  }

  changeImage(imageSrc) {
    // Prepare loading animation
    let showPreloader = () => {
      container.classList.add("loading");
    };
    // Change main image
    let nextImage = new Image();
    nextImage.onload = () => {
      this.mainTarget.src = nextImage.src;
      clearTimeout(timer);
    };
    nextImage.src = imageSrc;
    let timer = setTimeout(showPreloader, 500);
    this.mainTarget.src = "";
  }

  next() {
    if (this.index + 1 >= this.slideTargets.length) {
      this.index = 0;
    } else {
      this.index++;
    }
    this.showCurrentSlide();
    this.changeImage(this.slideTargets[this.index].dataset.preview);
  }

  prev() {
    if (this.index - 1 < 0) {
      this.index = this.slideTargets.length - 1;
    } else {
      this.index--;
    }
    this.showCurrentSlide();
    this.changeImage(this.slideTargets[this.index].dataset.preview);
  }

  showCurrentSlide() {
    this.slideTargets.forEach((element, index) => {
      if (index === this.index) {
        element.className = "active";
        element.scrollIntoView({
          behavior: "smooth",
          block: "nearest",
          inline: "start",
        });
      } else {
        element.className = "";
      }
    });
  }
}
