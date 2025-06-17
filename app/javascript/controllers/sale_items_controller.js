import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["options", "btn"];
  addProduct(e) {
    e.preventDefault();
    let id =
      this.element.querySelectorAll(".sales-form__product_fields").length + 1;
    let template = `
      <div class="sales-form__product_fields">
        <nav>
          <h6>New product</h6>
          <a class="danger" href="" data-action="sale-items#removeProduct">Remove</a>
        </nav>
        <input type="hidden" value="" name="sale[sale_items_attributes][${id}][product_id]" />
        <select name="sale[sale_items_attributes][${id}][product_id]">
          ${this.optionsTarget.innerHTML}
        </select>
        <input type="number" value="" name="sale[sale_items_attributes][${id}][qty]" placeholder="Qty">
        <input value="" step="any" type="number" name="sale[sale_items_attributes][${id}][price]" placeholder="Price">
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
