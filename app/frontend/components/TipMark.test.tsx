import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import TipMark from "./TipMark";

describe("TipMark", () => {
  beforeEach(() => {
    setViewportSize(1_024, 768);
    vi.spyOn(HTMLElement.prototype, "offsetWidth", "get").mockImplementation(
      function (this: HTMLElement) {
        return this.classList.contains("tip_mark__tooltip") ? 256 : 16;
      },
    );
    vi.spyOn(HTMLElement.prototype, "offsetHeight", "get").mockImplementation(
      function (this: HTMLElement) {
        return this.classList.contains("tip_mark__tooltip") ? 80 : 16;
      },
    );
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockImplementation(
      function (this: HTMLElement) {
        return this.classList.contains("tip_mark__tooltip")
          ? makeRect({ width: 256, height: 80 })
          : this.getAttribute("aria-label") === "More information"
            ? makeRect({ x: 100, y: 100, width: 16, height: 16 })
            : makeRect();
      },
    );
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("renders its tip through the top-layer portal on hover", async () => {
    const user = userEvent.setup();
    const { container } = render(<TipMark>Helpful context.</TipMark>);

    const trigger = screen.getByLabelText("More information");
    await user.hover(trigger);
    await flushFloatingPosition();

    const tooltip = screen.getByRole("tooltip");
    expect(tooltip).toHaveTextContent("Helpful context.");
    expect(tooltip).toHaveClass("tip_mark__tooltip");
    expect(container).not.toContainElement(tooltip);
    expect(trigger).toHaveClass("tip_mark__trigger");
    expect(trigger).toHaveAttribute("data-size", "regular");
    expect(trigger).not.toHaveAttribute("data-tone");
  });

  it("uses the requested trigger size and tone", () => {
    render(
      <TipMark size="large" tone="orange">
        Helpful context.
      </TipMark>,
    );

    const trigger = screen.getByLabelText("More information");
    expect(trigger).toHaveAttribute("data-size", "large");
    expect(trigger).toHaveAttribute("data-tone", "orange");
  });

  it("opens its tip when the mark receives keyboard focus", async () => {
    const user = userEvent.setup();
    render(<TipMark>Helpful context.</TipMark>);

    await user.tab();
    await flushFloatingPosition();

    expect(screen.getByRole("tooltip")).toHaveTextContent("Helpful context.");
  });

  it.each([
    ["right", 1_024, 768, makeRect({ x: 100, y: 100, width: 16, height: 16 })],
    ["left", 1_024, 768, makeRect({ x: 1_000, y: 100, width: 16, height: 16 })],
    ["bottom", 300, 768, makeRect({ x: 145, y: 10, width: 16, height: 16 })],
    ["top", 300, 768, makeRect({ x: 145, y: 740, width: 16, height: 16 })],
  ])(
    "places the tip on the %s when the trigger is near a viewport edge",
    async (placement, width, height, triggerRect) => {
      const user = userEvent.setup();
      setViewportSize(width, height);
      vi.mocked(HTMLElement.prototype.getBoundingClientRect).mockImplementation(
        function (this: HTMLElement) {
          return this.classList.contains("tip_mark__tooltip")
            ? makeRect({ width: 256, height: 80 })
            : this.getAttribute("aria-label") === "More information"
              ? triggerRect
              : makeRect();
        },
      );
      render(<TipMark>Helpful context.</TipMark>);

      await user.hover(screen.getByLabelText("More information"));
      await flushFloatingPosition();

      expect(screen.getByRole("tooltip")).toHaveAttribute("data-placement", placement);
    },
  );
});

async function flushFloatingPosition() {
  await act(async () => {});
}

function setViewportSize(width: number, height: number) {
  Object.defineProperties(document.documentElement, {
    clientWidth: { configurable: true, value: width },
    clientHeight: { configurable: true, value: height },
  });
  Object.defineProperties(document.body, {
    clientWidth: { configurable: true, value: width },
    clientHeight: { configurable: true, value: height },
  });
}

function makeRect({ x = 0, y = 0, width = 0, height = 0 }: Partial<DOMRect> = {}): DOMRect {
  return {
    x,
    y,
    width,
    height,
    top: y,
    right: x + width,
    bottom: y + height,
    left: x,
    toJSON: () => ({}),
  };
}
