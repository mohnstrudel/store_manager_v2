import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";
import { makeVersion, makeVersionProduct } from "./test/factories";
import type { ProductRecord, VersionRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Versions/Show", () => {
  it("renders version details and linked products", () => {
    renderShow();

    expect(
      screen.getByRole("heading", { name: "Classic" })
    ).toBeInTheDocument();
    expect(screen.getByText("Products")).toBeInTheDocument();
    expect(screen.getByText("Pokemon - Pikachu")).toBeInTheDocument();
  });

  it("links to the edit page", () => {
    renderShow();

    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/versions/1/edit"
    );
  });

  it("hides the products section when there are no products", () => {
    renderShow({ products: [] });

    expect(screen.queryByText("Products")).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the version after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this version" })
      );

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/versions/1");
    });

    it("does not destroy the version when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this version" })
      );

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  products = [makeVersionProduct()],
  version = makeVersion(),
}: {
  products?: ProductRecord[];
  version?: VersionRecord;
} = {}) {
  return render(<Show products={products} version={version} />);
}
