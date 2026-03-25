import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "img", "placeholder" ]

  static values = {
    placeholderSrc: String,
    src: String,
  }

  connect() {
    this.hasRequestedImage = false
    this.handleImageLoad = () => {
      if (!this.isShowingActualSource()) return
      this.showLoadedImage()
    }
    this.handleImageError = () => this.showFallback()

    this.imgTarget.addEventListener("load", this.handleImageLoad)
    this.imgTarget.addEventListener("error", this.handleImageError)

    if (!this.hasSource) return this.showFallback()
    if (this.isShowingActualSource() && this.isImageAlreadyLoaded()) return this.showLoadedImage()

    this.showLoading()

    if (this.isNearViewport()) {
      this.hasRequestedImage = true
      this.loadImage()
      return
    }

    this.observeVisibility()
  }

  disconnect() {
    this.imgTarget.removeEventListener("load", this.handleImageLoad)
    this.imgTarget.removeEventListener("error", this.handleImageError)
    this.visibilityObserver?.disconnect()
    this.visibilityObserver = null
  }

  observeVisibility() {
    if (this.visibilityObserver) return

    this.visibilityObserver = new IntersectionObserver(
      (entries) => this.handleIntersection(entries),
      {
        root: null,
        rootMargin: "0% 0% 30% 0%",
        threshold: 0.1,
      },
    )

    this.visibilityObserver.observe(this.imgTarget)
  }

  handleIntersection(entries) {
    if (!entries.some((entry) => entry.isIntersecting)) return
    if (this.hasRequestedImage) return

    this.hasRequestedImage = true
    this.visibilityObserver?.disconnect()
    this.visibilityObserver = null
    this.loadImage()
  }

  isNearViewport() {
    const rect = this.imgTarget.getBoundingClientRect()

    return rect.top < window.innerHeight * 1.3 && rect.bottom > 0
  }

  loadImage() {
    if (!this.hasSource) return this.showFallback()

    this.showLoading()
    this.imgTarget.src = this.srcValue
    requestAnimationFrame(() => {
      if (this.isImageAlreadyLoaded()) this.showLoadedImage()
    })
  }

  showLoadedImage() {
    this.hidePlaceholder()
    this.imgTarget.classList.remove("hidden", "loading", "not-found")
    this.imgTarget.style.height = "fit-content"
  }

  showLoading() {
    this.hidePlaceholder()
    this.imgTarget.classList.remove("hidden", "not-found")
    this.imgTarget.classList.add("loading")
    this.imgTarget.style.height = "100%"
  }

  showFallback() {
    this.showPlaceholder()
    this.imgTarget.classList.remove("loading")
    this.imgTarget.classList.add("hidden", "not-found")
  }

  isImageAlreadyLoaded() {
    return this.imgTarget.complete && this.imgTarget.naturalWidth > 0
  }

  showPlaceholder() {
    if (!this.hasPlaceholderTarget) return
    this.placeholderTarget.classList.remove("hidden")
  }

  hidePlaceholder() {
    if (!this.hasPlaceholderTarget) return
    this.placeholderTarget.classList.add("hidden")
  }

  isShowingActualSource() {
    return this.imgTarget.getAttribute("src") === this.srcValue
  }

  get hasSource() {
    return this.hasSrcValue && this.srcValue !== ""
  }
}
