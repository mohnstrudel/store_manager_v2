import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["btn"];
  static values = { usedStoreNames: String, index: Number };

  connect() {
    this.indexValue = this.element.querySelectorAll(".store-info-fields").length;
  }

  get usedStoreNames() {
    const selects = this.element.querySelectorAll("select[name*='[store_name]'], input[name*='[store_name]']");
    return Array.from(selects).map(select => select.value);
  }

  get availableStoreNames() {
    const usedNames = this.usedStoreNames;
    const uniqueStores = ["shopify", "woo"];
    return uniqueStores.filter(name => !usedNames.includes(name));
  }

  addStoreInfo(e) {
    e.preventDefault();
    const newIndex = this.element.querySelectorAll(".store-info-fields").length;
    const availableUniqueNames = this.availableStoreNames;

    const optionsHtml = [
      `<option value="not_assigned">Not Assigned</option>`,
      ...availableUniqueNames.map(name =>
        `<option value="${name}">${name.charAt(0).toUpperCase() + name.slice(1)}</option>`
      )
    ].join("");

    const template = `
      <div class="store-info-fields border border-gray-200 dark:border-gray-800 rounded-xl p-4 pb-8 my-6 max-w-1/2" data-store-info-target="field">
        <div class="flex justify-between items-center">
          <h6>New Store Info</h6>
          <a class="btn-rounded btn-red" href="" data-action="click->store-info#remove">Remove</a>
        </div>
        <input type="hidden" name="store_infos[${newIndex}][id]" data-store-info-target="id">
        <fieldset class="flex justify-between gap-4">
          <div class="block w-1/3">
            <label for="store_infos_${newIndex}_store_name">Store</label>
            <select id="store_infos_${newIndex}_store_name" name="store_infos[${newIndex}][store_name]" class="select" data-store-info-target="storeNameInput">
              ${optionsHtml}
            </select>
          </div>
          <div class="block w-2/3">
            <label for="store_infos_${newIndex}_tag_list">Tags</label>
            <input id="store_infos_${newIndex}_tag_list" type="text" value="" name="store_infos[${newIndex}][tag_list]" placeholder="tag1, tag2, tag3">
          </div>
        </fieldset>
      </div>
    `;
    this.btnTarget.insertAdjacentHTML("beforebegin", template);
  }

  remove(e) {
    e.preventDefault();
    const field = e.target.closest(".store-info-fields");
    field.remove();
  }

  toggleDestroy(e) {
    const field = e.target.closest(".store-info-fields");
    const hiddenInput = field.querySelector("input[name$='[_destroy]']");
    const checkbox = e.target;

    if (checkbox.checked) {
      hiddenInput.value = "1";
      field.style.opacity = "0.5";
    } else {
      hiddenInput.value = "false";
      field.style.opacity = "1";
    }
  }
}
