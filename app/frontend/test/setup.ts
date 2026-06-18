// oxlint-disable-next-line import/no-unassigned-import
import "@testing-library/jest-dom";

const originalConsoleError = console.error.bind(console);

beforeEach(() => {
  vi.spyOn(console, "error").mockImplementation((...args) => {
    const msg = typeof args[0] === "string" ? args[0] : "";
    if (msg.includes("was not wrapped in act")) {
      throw new Error(msg);
    }
    originalConsoleError(...args);
  });
});

if (typeof globalThis.ResizeObserver === "undefined") {
  globalThis.ResizeObserver = class ResizeObserver {
    observe() {}

    unobserve() {}

    disconnect() {}
  };
}
