import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

export default class extends Controller {
  static targets = ["sizes", "versions", "colors", "list"];

  turboRenderHandler = () => {
    this.initializeSlimSelects();
  };

  allSizes = [];
  allVersions = [];
  allColors = [];
  selectedSizes = [];
  selectedVersions = [];
  selectedColors = [];

  connect() {
    this.initializeSlimSelects();
    document.addEventListener("turbo:render", this.turboRenderHandler);
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.turboRenderHandler);
    [this.sizesSelect, this.versionsSelect, this.colorsSelect].forEach(
      (select) => {
        if (select) select.destroy();
      },
    );
    ["Sizes", "Versions", "Colors"].forEach((key) => {
      localStorage.removeItem(`slimSelect_all${key}`);
    });
  }

  /**
   * Initializes SlimSelect instances for sizes, versions, and colors,
   * restoring their state and setting up event listeners.
   * Called on connect and turbo:render to ensure proper setup after page loads or Turbo navigations.
   */
  initializeSlimSelects() {
    this.sizesSelect = this.createSlimSelect({
      target: this.sizesTarget,
      storageKey: "sizes",
      allProp: "allSizes",
      selectedProp: "selectedSizes",
    });

    this.versionsSelect = this.createSlimSelect({
      target: this.versionsTarget,
      storageKey: "versions",
      allProp: "allVersions",
      selectedProp: "selectedVersions",
    });

    this.colorsSelect = this.createSlimSelect({
      target: this.colorsTarget,
      storageKey: "colors",
      allProp: "allColors",
      selectedProp: "selectedColors",
    });

    this.restoreAndSetSelected("sizes", this.sizesSelect);
    this.restoreAndSetSelected("versions", this.versionsSelect);
    this.restoreAndSetSelected("colors", this.colorsSelect);
  }

  /**
   * Creates a SlimSelect instance for a given target element with event handling.
   * @param {HTMLElement} target - The select element to initialize.
   * @param {string} storageKey - Key for localStorage.
   * @param {string} allProp - Property name for all options (e.g., 'allSizes').
   * @param {string} selectedProp - Property name for selected options (e.g., 'selectedSizes').
   * @returns {SlimSelect} The initialized SlimSelect instance.
   */
  createSlimSelect({ target, storageKey, allProp, selectedProp }) {
    return new SlimSelect({
      select: target,
      events: {
        afterChange: (selectedOptions) => {
          this[selectedProp] = selectedOptions;
          this[allProp] = this[`${storageKey}Select`].getData();
          this.saveAllOptions(storageKey);
          this.renderEditions(this.editionsNames());
        },
      },
    });
  }

  /**
   * Restores saved options from localStorage and sets selected options for a SlimSelect instance.
   * Updates controller state and triggers rendering if needed.
   * @param {string} storageKey - Key for localStorage (e.g., 'sizes').
   * @param {SlimSelect} slimSelect - The SlimSelect instance to configure.
   */
  restoreAndSetSelected(storageKey, slimSelect) {
    const capitalizedKey = this.capitalize(storageKey);
    const allProp = `all${capitalizedKey}`;
    const selectedProp = `selected${capitalizedKey}`;

    const restored = this.restoreData(`all${capitalizedKey}`);
    if (restored) {
      this[allProp] = restored;
      slimSelect.setData(restored);
    } else {
      this[allProp] = slimSelect.getData();
      slimSelect.setData(this[allProp]);
    }

    const selectedIds = slimSelect.getSelected();
    if (selectedIds.length > 0) {
      this[selectedProp] = this[allProp].filter((option) =>
        selectedIds.includes(option.value),
      );
      this.renderEditions(this.editionsNames());
    }
  }

  saveAllOptions(storageKey) {
    const capitalizedKey = this.capitalize(storageKey);
    localStorage.setItem(
      `slimSelect_all${capitalizedKey}`,
      JSON.stringify(this[`all${capitalizedKey}`]),
    );
  }

  restoreData(storageKey) {
    const data = localStorage.getItem(`slimSelect_${storageKey}`);
    return data ? JSON.parse(data) : null;
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
  }

  /**
   * Generates a list of edition names and attributes based on selected sizes, versions, and colors because SlimSelect returns only ids of values, e.g. instead of "Black" it returns 42.
   * Handles combinations by iterating through all selected options or using null as a fallback.
   * @returns {Array<{attributes: Object, title: string}>} Array of edition objects with attributes and display titles.
   */
  editionsNames() {
    let editionsNames = [];
    const sizes = this.selectedSizes.length > 0 ? this.selectedSizes : [null];
    const versions =
      this.selectedVersions.length > 0 ? this.selectedVersions : [null];
    const colors =
      this.selectedColors.length > 0 ? this.selectedColors : [null];

    for (const size of sizes) {
      for (const version of versions) {
        for (const color of colors) {
          const attributes = {};
          if (size?.value) attributes.size_id = size.value;
          if (version?.value) attributes.version_id = version.value;
          if (color?.value) attributes.color_id = color.value;
          if (Object.keys(attributes).length > 0) {
            const title = [size?.text, version?.text, color?.text]
              .filter((el) => !!el)
              .join(" | ");
            editionsNames.push({ attributes, title });
          }
        }
      }
    }
    return editionsNames;
  }

  renderEditions(editions) {
    this.listTarget.classList.remove("hidden");
    this.listTarget.innerHTML = editions.reduce(
      (result, edition) =>
        result +
        `<li class="bg-blue-200/30 text-blue-950 dark:bg-blue-300/30 dark:text-blue-200 px-3 py-1 rounded-lg">${edition.title}</li>`,
      "",
    );
  }
}
