import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template"]
  static values = { index: Number }

  connect() {
    const existingEditions = document.querySelectorAll(".edition-fields").length
    this.indexValue = existingEditions
    this.boundRefreshEditionOptions = this.refreshEditionOptions.bind(this)
    this.productAttributeSelects().forEach((select) => {
      select.addEventListener("change", this.boundRefreshEditionOptions)
    })
  }

  disconnect() {
    this.productAttributeSelects().forEach((select) => {
      select.removeEventListener("change", this.boundRefreshEditionOptions)
    })
  }

  add() {
    const content = this.templateTarget.innerHTML.replace(/NEW_INDEX/g, this.indexValue++)
    const template = document.createElement("template")
    template.innerHTML = content.trim()

    const editionField = template.content.firstElementChild
    if (!editionField) return

    this.populateEditionOptions(editionField)
    this.containerTarget.appendChild(editionField)
  }

  remove(e) {
    e.preventDefault()
    const field = e.target.closest(".edition-fields")
    field.remove()
  }

  populateEditionOptions(editionField) {
    const sizeOptions = this.selectedProductOptions("size_ids")
    const versionOptions = this.selectedProductOptions("version_ids")
    const colorOptions = this.selectedProductOptions("color_ids")

    this.populateEditionSelect(editionField, "size", sizeOptions)
    this.populateEditionSelect(editionField, "version", versionOptions)
    this.populateEditionSelect(editionField, "color", colorOptions)
  }

  populateEditionSelect(editionField, attributeName, options) {
    const select = editionField.querySelector(`[name$="[${attributeName}_id]"]`)
    if (!select) return

    const currentValue = select.value
    const currentOption = select.selectedOptions[0]
    const blankOption = new Option("", "")
    const nextOptions = [...options]

    if (currentValue && currentOption && !nextOptions.some((option) => option.value === currentValue)) {
      nextOptions.unshift({ text: currentOption.text, value: currentValue })
    }

    select.replaceChildren(blankOption)

    nextOptions.forEach(({ text, value }) => {
      select.add(new Option(text, value))
    })

    select.value = currentValue
  }

  refreshEditionOptions() {
    this.containerTarget.querySelectorAll(".edition-fields").forEach((editionField) => {
      this.populateEditionOptions(editionField)
    })
  }

  selectedProductOptions(attributeName) {
    const form = this.element.closest("form")
    const select = form?.querySelector(`#product_${attributeName}`)
    if (!select) return []

    const selectedOptions = Array.from(select.selectedOptions)
    if (selectedOptions.length > 0) {
      return selectedOptions.map((option) => ({
        text: option.text,
        value: option.value
      }))
    }

    const slimSelectValues = this.selectedSlimSelectOptions(select)
    return slimSelectValues.map((option) => ({
      text: option.text,
      value: option.value
    }))
  }

  selectedSlimSelectOptions(select) {
    const slimSelect = select.parentElement?.querySelector(".ss-main")
    if (!slimSelect) return []

    const selectedLabels = Array.from(slimSelect.querySelectorAll(".ss-value-text, .ss-single"))
      .map((element) => element.textContent.trim())
      .filter((label) => label.length > 0)

    return Array.from(select.options).filter((option) => selectedLabels.includes(option.text.trim()))
  }

  productAttributeSelects() {
    const form = this.element.closest("form")
    if (!form) return []

    return ["size_ids", "version_ids", "color_ids"]
      .map((attributeName) => form.querySelector(`#product_${attributeName}`))
      .filter(Boolean)
  }
}
