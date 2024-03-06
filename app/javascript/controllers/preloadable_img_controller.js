import { Controller } from "@hotwired/stimulus";

export default class PreloadableImg extends Controller {
  static targets = ["skeleton", "img"];

  static values = {
    src: String,
  };

  observer = null;
  isObserved = false;

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      {
        root: null,
        rootMargin: "0% 0% 25% 0%",
        threshold: 0.1,
      },
    );
    this.observer.observe(this.skeletonTarget);
  }

  disconnect() {
    this.observer.disconnect();
  }

  handleIntersection(entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        if (!this.isObserved) {
          this.isObserved = true;
          this.preloadImg(this.srcValue);
        }
      }
    });
  }

  preloadImg(imageSrc) {
    let img = new Image();
    img.onload = () => {
      this.imgTarget.src = img.src;
      this.displayImg();
    };
    img.onerror = () => {
      this.skeletonTarget.style = "";
      this.skeletonTarget.classList = "";
      this.skeletonTarget.innerHTML = "<i class='icn'>🧌</i>";
    };
    img.src = imageSrc;
    this.handleTurboFrameChange(img);
  }

  displayImg() {
    this.skeletonTarget.classList.toggle("visible");
    this.imgTarget.classList.toggle("visible");
  }

  handleTurboFrameChange(img) {
    let listener = addEventListener("turbo:before-fetch-request", (event) => {
      if (event.target.id === "products-index") {
        img.src = "";
        removeEventListener("turbo:before-fetch-request", listener);
      }
    });
  }
}
