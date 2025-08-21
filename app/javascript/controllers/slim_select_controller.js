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
    localStorage.removeItem(storageKey);
  }

  /**
   * Initializes SlimSelect instance, sets up event listeners, and restores saved state.
   * Called on connect and turbo:render to ensure proper setup after page loads or Turbo navigations.
   */
  init() {
    // Ensure element has an ID, fallback to a default if not present
    const elementId =
      this.element.id || this.element.name || "default-slim-select";
    this.storageKey = `slimSelect_${elementId}`;

    this.slimSelect = new SlimSelect({
      select: this.element,
      events: {
        afterChange: () => {
          localStorage.setItem(
            this.storageKey,
            JSON.stringify(this.slimSelect.getData()),
          );
        },
      },
    });

    this.restoreAndSetData();
  }

  /**
   * Restores saved options from localStorage and updates SlimSelect data.
   * If no saved data exists, initializes with current options.
   */
  restoreAndSetData() {
    const savedData = localStorage.getItem(this.storageKey);
    const options = savedData
      ? JSON.parse(savedData)
      : this.slimSelect.getData();
    this.slimSelect.setData(options);
    localStorage.setItem(this.storageKey, JSON.stringify(options));
  }
}
