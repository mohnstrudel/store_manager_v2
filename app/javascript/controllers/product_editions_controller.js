import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

export default class extends Controller {
  static targets = ["sizes", "versions", "colors", "list"];

  sizes = [];
  versions = [];
  colors = [];
  editions = [];
  turboRenderHandler = () => this.initializeSlimSelects();

  connect() {
    this.initializeSlimSelects();
    document.addEventListener("turbo:render", this.turboRenderHandler);
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.turboRenderHandler);
    if (this.sizesSelect) this.sizesSelect.destroy();
    if (this.versionsSelect) this.versionsSelect.destroy();
    if (this.colorsSelect) this.colorsSelect.destroy();
  }

  initializeSlimSelects() {
    if (this.hasSizesTarget) {
      this.sizesSelect = new SlimSelect({
        select: this.sizesTarget,
        events: {
          afterChange: this.setupAndRender("sizes"),
        },
      });
      this.initializeSelected(this.sizesSelect, this.setupAndRender("sizes"));
    }
    if (this.hasVersionsTarget) {
      this.versionsSelect = new SlimSelect({
        select: this.versionsTarget,
        events: {
          afterChange: this.setupAndRender("versions"),
        },
      });
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
      this.initializeSelected(this.colorsSelect, this.setupAndRender("colors"));
    }
  }

  setupAndRender(target) {
    return (options) => {
      this[target] = this.mapOptions(options);
      this.editions = this.buildEditions();
      this.renderEditionsList();
    };
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

  mapOptions(options) {
    return options.map((option) => ({
      id: option.value,
      value: option.text,
    }));
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
          if (size?.id) attributes.size_id = size.id;
          if (version?.id) attributes.version_id = version.id;
          if (color?.id) attributes.color_id = color.id;
          if (Object.keys(attributes).length > 0) {
            const title = [size?.value, version?.value, color?.value]
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
