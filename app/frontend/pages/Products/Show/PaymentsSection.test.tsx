import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePaymentItem } from "../test/factories";
import type { PaymentItemRecord } from "../types";
import PaymentsSection from "./PaymentsSection";

describe("Products/Show/PaymentsSection", () => {
  it("renders nothing without payments", () => {
    const { container } = renderPaymentsSection({ payments: [] });

    expect(container).toBeEmptyDOMElement();
  });

  it("renders the title and payments count in the header", () => {
    renderPaymentsSection({
      payments: [makePaymentItem({ id: 1 }), makePaymentItem({ id: 2 })],
    });

    expect(screen.getByRole("heading", { name: /Active Payments.*2/ })).toBeInTheDocument();
  });

  it("renders customer, date, price, and quantity for each payment", () => {
    renderPaymentsSection();

    expect(screen.getByRole("cell", { name: /Ash Ketchum/ })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "20 May 2026" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "30.00" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
  });

  describe("variant column", () => {
    it("shows the variant column when the product has variants", () => {
      renderPaymentsSection({
        hasVariants: true,
        payments: [makePaymentItem({ variant_title: "Red Edition" })],
      });

      expect(screen.getByRole("columnheader", { name: "Variant?" })).toBeInTheDocument();
      expect(screen.getByRole("cell", { name: "Red Edition" })).toBeInTheDocument();
    });

    it("hides the variant column when the product has no variants", () => {
      renderPaymentsSection();

      expect(screen.queryByRole("columnheader", { name: "Variant?" })).not.toBeInTheDocument();
    });
  });

  describe("payment context", () => {
    it("shows the sequence and expected parts for a scheduled payment", () => {
      renderPaymentsSection({
        payments: [makePaymentItem({ sequence: 2, expected_parts: 4, origin: null })],
      });

      expect(screen.getByText("Payment 2 of 4")).toBeInTheDocument();
    });

    it("links to the origin sale when only origin context is available", () => {
      renderPaymentsSection({
        payments: [
          makePaymentItem({
            sequence: null,
            expected_parts: null,
            origin: { path: "/sales/7", identifier: "#7007" },
          }),
        ],
      });

      expect(screen.getByRole("link", { name: "#7007" })).toHaveAttribute("href", "/sales/7");
    });

    it("falls back to a plain label without sequence or origin evidence", () => {
      renderPaymentsSection({
        payments: [makePaymentItem({ sequence: null, expected_parts: null, origin: null })],
      });

      expect(screen.getByText("Follow-up payment")).toBeInTheDocument();
    });
  });

  describe("row navigation", () => {
    it("visits the sale when the row is clicked", async () => {
      const user = userEvent.setup();
      renderPaymentsSection();

      await user.click(screen.getByRole("row", { name: /Ash Ketchum/ }));

      expect(router.visit).toHaveBeenCalledWith("/sales/1");
    });
  });

  describe("purchase item link", () => {
    it("links to the purchase item labeled with its warehouse", () => {
      renderPaymentsSection({
        payments: [
          makePaymentItem({ purchase_item_path: "/purchase_items/1", warehouse: "Tokyo" }),
        ],
      });

      expect(screen.getByRole("link", { name: /Tokyo/ })).toHaveAttribute(
        "href",
        "/purchase_items/1",
      );
    });

    it("renders without a purchase item link when nothing is linked", () => {
      renderPaymentsSection({
        payments: [makePaymentItem({ purchase_item_path: null })],
      });

      expect(screen.queryByRole("link", { name: /Purchase Item/ })).not.toBeInTheDocument();
    });
  });
});

type RenderPaymentsSectionOptions = {
  hasVariants?: boolean;
  payments?: PaymentItemRecord[];
  title?: string;
};

function renderPaymentsSection({
  hasVariants = false,
  payments = [makePaymentItem()],
  title = "Active Payments",
}: RenderPaymentsSectionOptions = {}) {
  return render(<PaymentsSection hasVariants={hasVariants} payments={payments} title={title} />);
}
