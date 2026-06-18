import { beforeEach, describe, expect, it, vi } from "vitest";
import type { KeyboardEvent, MouseEvent } from "react";
import { router } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "./rowNavigation";

beforeEach(() => {
  vi.spyOn(window, "open").mockReturnValue(null);
});

describe("stopRowNavigation", () => {
  it("stops event propagation", () => {
    const event = { stopPropagation: vi.fn<() => void>() };
    stopRowNavigation(event);
    expect(event.stopPropagation).toHaveBeenCalledOnce();
  });
});

describe("rowNavigationProps", () => {
  it("prefetches row destinations on hover and focus", () => {
    const props = rowNavigationProps("/products/1");

    props.onMouseEnter();
    props.onFocus();

    expect(router.prefetch).toHaveBeenCalledTimes(2);
    expect(router.prefetch).toHaveBeenCalledWith("/products/1", {
      method: "get",
    });
  });

  describe("onClick", () => {
    it("visits the path without modifier keys", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onClick({ metaKey: false, ctrlKey: false } as unknown as MouseEvent<HTMLTableRowElement>);

      expect(router.visit).toHaveBeenCalledWith("/products/1");
    });

    it("opens a new tab when metaKey is held", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onClick({ metaKey: true, ctrlKey: false } as unknown as MouseEvent<HTMLTableRowElement>);

      expect(window.open).toHaveBeenCalledWith("/products/1", "_blank", "noopener,noreferrer");
    });

    it("opens a new tab when ctrlKey is held", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onClick({ metaKey: false, ctrlKey: true } as unknown as MouseEvent<HTMLTableRowElement>);

      expect(window.open).toHaveBeenCalledWith("/products/1", "_blank", "noopener,noreferrer");
    });
  });

  describe("onAuxClick", () => {
    it("opens a new tab on middle-click (button 1)", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onAuxClick({ button: 1 } as unknown as MouseEvent<HTMLTableRowElement>);

      expect(window.open).toHaveBeenCalledWith("/products/1", "_blank", "noopener,noreferrer");
    });

    it("does nothing for other auxiliary buttons", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onAuxClick({ button: 2 } as unknown as MouseEvent<HTMLTableRowElement>);

      expect(window.open).not.toHaveBeenCalled();
    });
  });

  describe("onKeyDown", () => {
    it("visits the path when Enter is pressed", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onKeyDown({
        key: "Enter",
        metaKey: false,
        ctrlKey: false,
        preventDefault: vi.fn<() => void>(),
      } as unknown as KeyboardEvent<HTMLTableRowElement>);

      expect(router.visit).toHaveBeenCalledWith("/products/1");
    });

    it("visits the path when Space is pressed", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onKeyDown({
        key: " ",
        metaKey: false,
        ctrlKey: false,
        preventDefault: vi.fn<() => void>(),
      } as unknown as KeyboardEvent<HTMLTableRowElement>);

      expect(router.visit).toHaveBeenCalledWith("/products/1");
    });

    it("opens a new tab when Enter+metaKey is pressed", () => {
      const props = rowNavigationProps("/products/1");

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onKeyDown({
        key: "Enter",
        metaKey: true,
        ctrlKey: false,
        preventDefault: vi.fn<() => void>(),
      } as unknown as KeyboardEvent<HTMLTableRowElement>);

      expect(window.open).toHaveBeenCalledWith("/products/1", "_blank", "noopener,noreferrer");
    });

    it("does nothing for other keys", () => {
      const props = rowNavigationProps("/products/1");
      const preventDefault = vi.fn<() => void>();

      // eslint-disable-next-line @typescript-eslint/no-unsafe-type-assertion
      props.onKeyDown({
        key: "Tab",
        metaKey: false,
        ctrlKey: false,
        preventDefault,
      } as unknown as KeyboardEvent<HTMLTableRowElement>);

      expect(preventDefault).not.toHaveBeenCalled();
      expect(router.visit).not.toHaveBeenCalled();
      expect(window.open).not.toHaveBeenCalled();
    });
  });
});
