// oxlint-disable-next-line import/no-unassigned-import
import "@testing-library/jest-dom";

if (typeof globalThis.ResizeObserver === "undefined") {
  globalThis.ResizeObserver = class ResizeObserver {
    observe() {}

    unobserve() {}

    disconnect() {}
  };
}
