import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "button", "container", "template" ]
  static values = { index: Number, storeNames: Array }

  connect() {
    this.indexValue = this.storeInfoFields.length
    this.populateExistingStoreSelectors()
    this.refreshButtonState()
  }

  addStoreInfo(event) {
    event.preventDefault()
    const availableStoreNames = this.availableStoreNames
    if (availableStoreNames.length === 0) return

    this.containerTarget.insertAdjacentHTML("beforeend", this.nextFieldMarkup)
    const field = this.containerTarget.lastElementChild
    const select = field.querySelector("select[name*='[store_name]']")

    this.populateStoreNameOptions(select, availableStoreNames)
    this.refreshButtonState()
  }

  remove(event) {
    event.preventDefault()
    event.currentTarget.closest(".store-info-fields")?.remove()
    this.refreshButtonState()
  }

  toggleDestroy(event) {
    const field = event.target.closest(".store-info-fields")
    const hiddenInput = field.querySelector("input[name$='[_destroy]']")
    const checkbox = event.target

    if (checkbox.checked) {
      hiddenInput.value = "1"
      field.style.opacity = "0.5"
    } else {
      hiddenInput.value = "false"
      field.style.opacity = "1"
    }

    this.refreshButtonState()
  }

  refreshButtonState() {
    const hasAvailableNames = this.availableStoreNames.length > 0
    this.buttonTarget.disabled = !hasAvailableNames
    this.buttonTarget.classList.toggle("opacity-50", !hasAvailableNames)
    this.buttonTarget.classList.toggle("cursor-not-allowed", !hasAvailableNames)
  }

  populateExistingStoreSelectors() {
    this.storeInfoFields.forEach((field) => {
      const select = field.querySelector("select[name*='[store_name]']")
      if (!select) return

      const currentValue = select.value
      const availableStoreNames = this.availableStoreNamesFor(currentValue)

      this.populateStoreNameOptions(select, availableStoreNames)
      if (currentValue) select.value = currentValue
    })
  }

  populateStoreNameOptions(select, availableStoreNames) {
    if (!select) return

    select.replaceChildren(...this.storeNameOptions(availableStoreNames))
  }

  storeNameOptions(availableStoreNames) {
    return [
      this.buildOption("not_assigned", "Not Assigned"),
      ...availableStoreNames.map((name) => this.buildOption(name, this.humanize(name)))
    ]
  }

  buildOption(value, label) {
    const option = document.createElement("option")
    option.value = value
    option.textContent = label
    return option
  }

  humanize(name) {
    return name.charAt(0).toUpperCase() + name.slice(1)
  }

  get nextFieldMarkup() {
    return this.templateTarget.innerHTML.replace(/NEW_INDEX/g, this.indexValue++)
  }

  get storeInfoFields() {
    return Array.from(this.containerTarget.querySelectorAll(".store-info-fields"))
  }

  get usedStoreNames() {
    return this.storeInfoFields
      .filter((field) => !this.isMarkedForDestroy(field))
      .map((field) => field.querySelector("[name*='[store_name]']")?.value)
      .filter(Boolean)
  }

  get availableStoreNames() {
    return this.storeNamesValue.filter((name) => !this.usedStoreNames.includes(name))
  }

  availableStoreNamesFor(currentValue) {
    if (!currentValue || currentValue === "not_assigned") return this.availableStoreNames

    return this.availableStoreNames.includes(currentValue) ? this.availableStoreNames : [currentValue, ...this.availableStoreNames]
  }

  isMarkedForDestroy(field) {
    return field.querySelector("input[name$='[_destroy]']")?.value === "1"
  }
}
