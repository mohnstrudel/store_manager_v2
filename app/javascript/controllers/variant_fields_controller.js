import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["duplicateWarning", "title"]
  static values = { existing: Array }

  connect() {
    // Parse existing variants from JSON value
    if (this.hasExistingValue) {
      this.existingVariants = this.existingValue
    } else {
      this.existingVariants = []
    }

    // Store the original title on connect
    if (this.hasTitleTarget) {
      this.originalTitle = this.titleTarget.textContent.trim()
      // Don't show arrow on initial load if it's a new variant
      if (this.originalTitle !== "New Variant") {
        this.hasOriginalTitle = true
      }
    }
  }

  toggleDestroy(e) {
    const checkbox = e.target;
    this.element.style.opacity = checkbox.checked ? "0.5" : "1";
  }

  checkDuplicate() {
    const sizeId = this.element.querySelector('[name$="[size_id]"]')?.value
    const versionId = this.element.querySelector('[name$="[version_id]"]')?.value
    const colorId = this.element.querySelector('[name$="[color_id]"]')?.value

    if (!sizeId && !versionId && !colorId) {
      this.duplicateWarningTarget.classList.add("hidden")
      return
    }

    // Get the ID of the current variant (for editing existing variants)
    const variantIdInput = this.element.querySelector('[name$="[id]"]')
    const currentVariantId = variantIdInput?.value

    const isDuplicate = this.existingVariants.some(variant => {
      // Skip comparing with itself when editing
      if (currentVariantId && variant.id == currentVariantId) return false

      const matchSize = (!sizeId && !variant.size_id) || variant.size_id == sizeId
      const matchVersion = (!versionId && !variant.version_id) || variant.version_id == versionId
      const matchColor = (!colorId && !variant.color_id) || variant.color_id == colorId
      return matchSize && matchVersion && matchColor
    })

    if (isDuplicate) {
      this.duplicateWarningTarget.classList.remove("hidden")
    } else {
      this.duplicateWarningTarget.classList.add("hidden")
    }
  }

  updateTitle() {
    if (!this.hasTitleTarget) return

    const sizeSelect = this.element.querySelector('[name$="[size_id]"]')
    const versionSelect = this.element.querySelector('[name$="[version_id]"]')
    const colorSelect = this.element.querySelector('[name$="[color_id]"]')

    const parts = []

    if (sizeSelect?.selectedOptions[0]?.value) {
      parts.push(sizeSelect.selectedOptions[0].text)
    }
    if (versionSelect?.selectedOptions[0]?.value) {
      parts.push(versionSelect.selectedOptions[0].text)
    }
    if (colorSelect?.selectedOptions[0]?.value) {
      parts.push(colorSelect.selectedOptions[0].text)
    }

    const newTitle = parts.length > 0 ? parts.join(" | ") : "Base Model"

    if (this.hasOriginalTitle && this.originalTitle !== newTitle) {
      this.titleTarget.innerHTML = `<span class="font-normal">${this.originalTitle}  →  </span> ${newTitle}`
    } else {
      this.titleTarget.textContent = newTitle
    }
  }
}
