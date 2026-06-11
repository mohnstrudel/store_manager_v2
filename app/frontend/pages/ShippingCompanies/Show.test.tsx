import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";
import { makeShippingCompany, makeShippingCompanyPurchaseItem } from "./test/factories";
import type { PurchaseItemRecord, ShippingCompanyRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("ShippingCompanies/Show", () => {
  it("renders shipping company details and linked purchase items", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "DHL" })).toBeInTheDocument();
    expect(screen.getByText("Purchase Items")).toBeInTheDocument();
    expect(screen.getByText("Pokemon - Pikachu")).toBeInTheDocument();
  });

  it("links to the edit page", () => {
    renderShow();

    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/shipping_companies/1/edit",
    );
  });

  it("hides the purchase items section when there are none", () => {
    renderShow({ purchaseItems: [] });

    expect(screen.queryByText("Purchase Items")).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the shipping company after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this shipping company" }));

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/shipping_companies/1");
    });

    it("does not destroy the shipping company when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this shipping company" }));

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  purchaseItems = [makeShippingCompanyPurchaseItem()],
  shippingCompany = makeShippingCompany(),
}: {
  purchaseItems?: PurchaseItemRecord[];
  shippingCompany?: ShippingCompanyRecord;
} = {}) {
  return render(<Show purchaseItems={purchaseItems} shippingCompany={shippingCompany} />);
}
