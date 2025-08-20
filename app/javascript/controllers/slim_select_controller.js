import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

// Connects to data-controller="slim-select"
export default class extends Controller {
  turboRenderHandler = () => {
    this.init();
  };

  connect() {
    this.init();
    document.addEventListener("turbo:render", this.turboRenderHandler);
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.turboRenderHandler);
    if (this.slimSelect) this.slimSelect.destroy();
    localStorage.removeItem(`slimSelect_${this.element.id}`);
  }

  init() {
    this.slimSelect = new SlimSelect({
      select: this.element,
      events: {
        afterChange: this.saveToLocalStorage(this.element.id),
      },
    });
    this.restoreFromLocalStorage(this.element.id);
  }

  saveToLocalStorage(id) {
    return (slimSelectOptions) => {
      localStorage.setItem(
        `slimSelect_${id}`,
        JSON.stringify(slimSelectOptions),
      );
    };
  }

  restoreFromLocalStorage(id) {
    const savedData = localStorage.getItem(`slimSelect_${id}`);
    if (savedData) {
      const values = JSON.parse(savedData);
      this.slimSelect.setSelected(values.map((item) => item.value));
    }
  }
}
