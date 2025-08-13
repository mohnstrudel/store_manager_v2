import { Controller } from "@hotwired/stimulus";

export default class PreloadableImg extends Controller {
  static targets = ["img"];

  static values = {
    src: String,
  };

  observers = [];
  isObserved = false;
  placeholder = null;

  connect() {
    if (this.srcValue) {
      this.displayLoading();
    } else {
      this.displayNothing();
    }
    this.placeholder = document.querySelector("#preloader-img__placeholder");
    this.useIntersectionObserver();
    this.useMutationObserver();
  }

  disconnect() {
    if (this.observers.length > 0) {
      this.observers.forEach((observer) => {
        observer.disconnect();
      });
      this.observers = [];
    }
  }

  useMutationObserver() {
    let observer = new MutationObserver((mutations) => {
      const mutation = mutations[0];
      const newUrl = mutation.target.src;
      const isTransparent = newUrl.includes("data:image");

      if (isTransparent) {
        this.displayLoading();
        return;
      }

      this.displayNothing();
    });

    observer.observe(this.imgTarget, {
      attributes: true,
      attributeFilter: ["src"],
    });

    this.observers.push(observer);
  }

  useIntersectionObserver() {
    let observer = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      {
        root: null,
        rootMargin: "0% 0% 30% 0%",
        threshold: 0.1,
      },
    );
    observer.observe(this.imgTarget);
    this.observers.push(observer);
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
    if (imageSrc === "") {
      this.displayNothing();
      return;
    }
    let img = new Image();
    img.fetchPriority = "low";
    this.imgTarget.src =
      "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
    img.onload = () => {
      this.imgTarget.src = img.src;
    };
    img.onerror = () => {
      this.imgTarget.src = "";
    };
    img.src = imageSrc;
    this.handleTurboFrameChange(img);
  }

  displayImg() {
    if (this.placeholder) this.placeholder.classList.add("hidden");
    this.imgTarget.classList.remove("hidden");
    this.imgTarget.classList.remove("loading");
    this.imgTarget.classList.remove("not-found");
    this.imgTarget.style.height = "fit-content";
  }

  displayLoading() {
    this.imgTarget.style.height = "100%";
    this.imgTarget.classList.remove("hidden");
    this.imgTarget.classList.remove("not-found");
    this.imgTarget.classList.add("loading");
  }

  displayNothing() {
    if (this.placeholder) {
      document
        .querySelector("#preloader-img__placeholder")
        .classList.remove("hidden");
    }
    if (this.imgTarget.classList.contains("not-found")) return;
    this.imgTarget.classList.remove("loading");
    this.imgTarget.classList.add("not-found");
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
