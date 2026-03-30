import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

// Connects to data-controller="slim-select"
export default class extends Controller {
  turboRenderHandler = () => {
    window.requestAnimationFrame(() => this.init());
  };

  connect() {
    this.init();
    document.addEventListener("turbo:render", this.turboRenderHandler);
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.turboRenderHandler);
    this.destroySlimSelect();
  }

  init() {
    if (this.hasSlimSelectUi()) return;

    this.destroySlimSelect();
    this.slimSelect = new SlimSelect({
      select: this.element,
    });
  }

  destroySlimSelect() {
    if (!this.slimSelect) return;

    this.slimSelect.destroy();
    this.slimSelect = null;
  }

  hasSlimSelectUi() {
    return Boolean(this.element.parentElement?.querySelector(".ss-main"));
  }
}
