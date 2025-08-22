import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["options", "btn"];
  addProduct(e) {
    e.preventDefault();
    let id =
      this.element.querySelectorAll(".sales-form__product_fields").length + 1;
    let template = `
      <div class="sales-form__product_fields border border-gray-200 dark:border-gray-800 rounded-xl p-4 pb-8 my-6 max-w-2/3">
        <div class="flex justify-between items-center">
          <h6>New product</h6>
          <a class="btn-rounded btn-red" href="" data-action="sale-items#removeProduct">Remove</a>
        </div>
        <label for="sale_${id}_product">Product</label>
          <input type="hidden" value="" name="sale[sale_items_attributes][${id}][product_id]" />
        <select id="sale_${id}_product" name="sale[sale_items_attributes][${id}][product_id]" data-controller="slim-select">
          ${this.optionsTarget.innerHTML}
        </select>
        <label for="sale_${id}_product_amount">Amount</label>
        <input id="sale_${id}_product_amount" type="number" value="" name="sale[sale_items_attributes][${id}][qty]" placeholder="Amount">
        <label for="sale_${id}_product_price">Price</label>
        <input id="sale_${id}_product_price" value="" step="any" type="number" name="sale[sale_items_attributes][${id}][price]" placeholder="Price">
      </div>
    `;
    this.btnTarget.insertAdjacentHTML("beforebegin", template);
  }
  removeProduct(e) {
    e.preventDefault();
    let wrapper = e.target.closest(".sales-form__product_fields");
    wrapper.remove();
  }
}
