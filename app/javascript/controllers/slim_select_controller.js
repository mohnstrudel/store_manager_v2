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
  init() {
    this.slimSelect = new SlimSelect({
      select: this.element,
    });
  }
  disconnect() {
    document.removeEventListener("turbo:render", this.turboRenderHandler);
    if (this.slimSelect) this.slimSelect.destroy();
  }
}
