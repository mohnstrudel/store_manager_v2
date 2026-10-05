import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import Show from "./Show";
import { makeColor, makeColorProduct } from "./test/factories";
import type { ColorRecord, ProductRecord } from "./types";

describe("Colors/Show", () => {
  it("renders color details and linked products", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Azure" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Studio Ghibli - Spirited Away" })).toHaveAttribute(
      "href",
      "/products/10",
    );
  });

  it("links to the edit page", () => {
    renderShow();

    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/colors/1/edit");
  });

  it("hides the products section when there are no linked products", () => {
    renderShow({ products: [] });

    expect(screen.queryByRole("heading", { name: "Products" })).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the color after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this color" }));

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/colors/1");
    });

    it("does not destroy the color when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this color" }));

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  color = makeColor(),
  products = [makeColorProduct()],
}: {
  color?: ColorRecord;
  products?: ProductRecord[];
} = {}) {
  return render(<Show color={color} products={products} />);
}
