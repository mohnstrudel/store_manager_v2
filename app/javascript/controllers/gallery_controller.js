import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["slide", "main"];

  initialize() {
    this.index = 0;
    this.showCurrentSlide();
  }

  select(event) {
    event.preventDefault();
    // Change navigation
    this.index = Number(event.target.dataset.id);
    this.showCurrentSlide();
    this.changeImage(event.target.dataset.preview);
  }

  togglePreloader(switcher) {
    let container = document.querySelector(".gallery__main");
    container.classList.toggle("loading", switcher);
  }

  changeImage(imageSrc) {
    this.mainTarget.src = "";
    this.togglePreloader(true);
    let nextImage = new Image();
    nextImage.onload = () => {
      this.mainTarget.src = nextImage.src;
      this.togglePreloader(false);
    };
    nextImage.fetchPriority = "high";
    nextImage.src = imageSrc;
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
