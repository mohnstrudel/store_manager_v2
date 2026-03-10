import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "image"]

  connect() {
    this.isZoomed = false
  }

  enableZoom() {
    this.imageTarget.classList.add('scale-250')
    this.imageTarget.classList.remove('object-cover')
    this.imageTarget.classList.remove('h-full')
    this.imageTarget.classList.remove('w-full')
    requestAnimationFrame(() => {
      this.imageTarget.classList.add('object-contain')
    })
    this.isZoomed = true
  }

  disableZoom() {
    this.imageTarget.classList.remove('scale-250')
    this.imageTarget.style.transform = ''
    requestAnimationFrame(() => {
      this.imageTarget.classList.add('h-full')
      this.imageTarget.classList.add('w-full')
      this.imageTarget.classList.remove('object-contain')
      this.imageTarget.classList.add('object-cover')
    })
    this.isZoomed = false
  }

  onMouseMove(e) {
    if (!this.isZoomed) return

    const containerRect = this.containerTarget.getBoundingClientRect()

    const relativeMouseX = (e.clientX - containerRect.left) / containerRect.width
    const relativeMouseY = (e.clientY - containerRect.top) / containerRect.height

    const offsetFromCenterX = relativeMouseX - 0.5
    const offsetFromCenterY = relativeMouseY - 0.5

    const translateX = -offsetFromCenterX * 100
    const translateY = -offsetFromCenterY * 100

    this.imageTarget.style.transform = `translate(${translateX}%, ${translateY}%)`
  }
}
