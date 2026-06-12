import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";
import { makeSupplier, makeSupplierPurchase } from "./test/factories";
import type { PurchaseRecord, SupplierRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Suppliers/Show", () => {
  it("renders supplier details and linked purchases", () => {
    renderShow();

    expect(
      screen.getByRole("heading", { name: "GoodSmile" })
    ).toBeInTheDocument();
    expect(screen.getByText("Purchases")).toBeInTheDocument();
    expect(screen.getByText("Pokemon - Pikachu")).toBeInTheDocument();
  });

  it("links to the edit page", () => {
    renderShow();

    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/suppliers/1/edit"
    );
  });

  it("hides the purchases section when there are no purchases", () => {
    renderShow({ purchases: [] });

    expect(screen.queryByText("Purchases")).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the supplier after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this supplier" })
      );

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/suppliers/1");
    });

    it("does not destroy the supplier when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(
        screen.getByRole("button", { name: "Destroy this supplier" })
      );

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  purchases = [makeSupplierPurchase()],
  supplier = makeSupplier(),
}: {
  purchases?: PurchaseRecord[];
  supplier?: SupplierRecord;
} = {}) {
  return render(<Show purchases={purchases} supplier={supplier} />);
}
