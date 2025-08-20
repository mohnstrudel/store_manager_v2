import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

export default class extends Controller {
  static targets = ["sizes", "versions", "colors", "list"];

  sizes = [];
  versions = [];
  colors = [];
  editions = [];
  turboRenderHandler = () => {
    this.initializeSlimSelects();
  };

  connect() {
    this.initializeSlimSelects();
    document.addEventListener("turbo:render", this.turboRenderHandler);
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.turboRenderHandler);
    if (this.sizesSelect) this.sizesSelect.destroy();
    if (this.versionsSelect) this.versionsSelect.destroy();
    if (this.colorsSelect) this.colorsSelect.destroy();
    localStorage.removeItem("slimSelect_sizes");
    localStorage.removeItem("slimSelect_versions");
    localStorage.removeItem("slimSelect_colors");
  }

  initializeSlimSelects() {
    if (this.hasSizesTarget) {
      this.sizesSelect = new SlimSelect({
        select: this.sizesTarget,
        events: {
          afterChange: this.setupAndRender("sizes"),
        },
      });
      this.restoreFromLocalStorage(this.sizesSelect, "sizes");
      this.initializeSelected(this.sizesSelect, this.setupAndRender("sizes"));
    }
    if (this.hasVersionsTarget) {
      this.versionsSelect = new SlimSelect({
        select: this.versionsTarget,
        events: {
          afterChange: this.setupAndRender("versions"),
        },
      });
      this.restoreFromLocalStorage(this.versionsSelect, "versions");
      this.initializeSelected(
        this.versionsSelect,
        this.setupAndRender("versions"),
      );
    }
    if (this.hasColorsTarget) {
      this.colorsSelect = new SlimSelect({
        select: this.colorsTarget,
        events: {
          afterChange: this.setupAndRender("colors"),
        },
      });
      this.restoreFromLocalStorage(this.colorsSelect, "colors");
      this.initializeSelected(this.colorsSelect, this.setupAndRender("colors"));
    }
  }

  setupAndRender(target) {
    return (slimSelectOptions) => {
      this[target] = slimSelectOptions;
      localStorage.setItem(
        `slimSelect_${target}`,
        JSON.stringify(slimSelectOptions),
      );
      this.editions = this.buildEditions();
      this.renderEditionsList();
    };
  }

  restoreFromLocalStorage(slimSelector, target) {
    const savedData = localStorage.getItem(`slimSelect_${target}`);
    if (savedData) {
      const values = JSON.parse(savedData);
      this[target] = values;
      slimSelector.setSelected(values.map((item) => item.value));
    }
  }

  initializeSelected(slimSelector, renderer) {
    const selectedItems = slimSelector.getSelected();
    if (selectedItems.length > 0) {
      const options = slimSelector.getData();
      const selectedOptions = options.filter((option) => {
        return selectedItems.includes(option.value);
      });
      renderer(selectedOptions);
    }
  }

  buildEditions() {
    let new_editions = [];
    const sizes = this.sizes.length > 0 ? this.sizes : [null];
    const versions = this.versions.length > 0 ? this.versions : [null];
    const colors = this.colors.length > 0 ? this.colors : [null];
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
            new_editions.push({ attributes, title });
          }
        }
      }
    }
    return new_editions;
  }

  renderEditionsList() {
    this.listTarget.classList.remove("hidden");
    this.listTarget.innerHTML = this.editions.reduce(
      (result, edition) =>
        result +
        `<li class=" bg-blue-200/30 text-blue-950 px-3 py-1 rounded-lg">${edition.title}</li>`,
      "",
    );
  }
}
