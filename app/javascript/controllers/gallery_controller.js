import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "slide", "main", "mainFrame" ]

  connect() {
    this.selectedIndex = 0
    this.renderSelection({ scroll: false })
    this.reconcileLoadedImages()
    requestAnimationFrame(() => this.reconcileLoadedImages())
  }

  select(event) {
    event.preventDefault()
    this.showIndex(Number(event.currentTarget.dataset.id))
  }

  next() {
    this.showIndex(this.wrapIndex(this.selectedIndex + 1))
  }

  prev() {
    this.showIndex(this.wrapIndex(this.selectedIndex - 1))
  }

  handleThumbLoad(event) {
    this.showThumbImage(event.currentTarget)
  }

  handleThumbError(event) {
    this.hideThumbLoader(event.currentTarget)
  }

  handleMainLoad() {
    this.finishMainLoading()
  }

  handleMainError() {
    this.failMainLoading()
  }

  showIndex(index) {
    if (this.selectedIndex === index) return

    this.selectedIndex = index
    this.renderSelection()
    this.loadCurrentImage()
  }

  renderSelection({ scroll = true } = {}) {
    this.slideTargets.forEach((slide, index) => {
      const isSelected = index === this.selectedIndex

      slide.classList.toggle("active", isSelected)

      if (isSelected && scroll) {
        slide.scrollIntoView({
          behavior: "smooth",
          block: "nearest",
          inline: "start",
        })
      }
    })
  }

  loadCurrentImage() {
    const slide = this.currentSlide
    if (!slide) return

    this.startMainLoading()

    const image = new Image()
    image.fetchPriority = "high"
    image.onload = () => {
      this.mainTarget.src = image.src
      this.mainTarget.alt = slide.dataset.alt || this.mainTarget.alt
      this.finishMainLoading()
    }
    image.onerror = () => {
      this.mainTarget.src = ""
      this.failMainLoading()
    }
    image.src = slide.dataset.preview
  }

  reconcileLoadedImages() {
    this.slideTargets.forEach((slide) => {
      const image = slide.querySelector("img")
      if (image?.complete && image.naturalWidth > 0) {
        this.showThumbImage(image)
      }
    })

    if (this.mainTarget.complete && this.mainTarget.naturalWidth > 0) {
      this.finishMainLoading()
    }
  }

  showThumbImage(image) {
    image.classList.remove("hidden")
    image.closest(".gallery-thumb__frame")?.classList.remove("loading")
  }

  hideThumbLoader(image) {
    image.closest(".gallery-thumb__frame")?.classList.remove("loading")
  }

  startMainLoading() {
    this.mainTarget.classList.add("hidden")
    this.mainFrameTarget.classList.add("loading")
  }

  finishMainLoading() {
    this.mainTarget.classList.remove("hidden")
    this.mainFrameTarget.classList.remove("loading")
  }

  failMainLoading() {
    this.mainTarget.classList.add("hidden")
    this.mainFrameTarget.classList.remove("loading")
  }

  wrapIndex(index) {
    if (this.slideTargets.length === 0) return 0

    return (index + this.slideTargets.length) % this.slideTargets.length
  }

  get currentSlide() {
    return this.slideTargets[this.selectedIndex]
  }
}
