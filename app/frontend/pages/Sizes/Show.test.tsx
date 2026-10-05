import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import Show from "./Show";
import { makeSize, makeSizeProduct } from "./test/factories";
import type { ProductRecord, SizeRecord } from "./types";

describe("Sizes/Show", () => {
  it("renders size details and linked products", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "1:6" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "Studio Ghibli - Spirited Away" })).toBeInTheDocument();
  });

  it("links to the edit page", () => {
    renderShow();

    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/sizes/1/edit");
  });

  it("hides the products section when there are no linked products", () => {
    renderShow({ products: [] });

    expect(screen.queryByRole("heading", { name: "Products" })).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the size after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this size" }));

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/sizes/1");
    });

    it("does not destroy the size when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this size" }));

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  products = [makeSizeProduct()],
  size = makeSize(),
}: {
  products?: ProductRecord[];
  size?: SizeRecord;
} = {}) {
  return render(<Show products={products} size={size} />);
}
