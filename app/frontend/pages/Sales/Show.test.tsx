import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makeSalePaymentPlan } from "@/test/factories";

import Show from "./Show";
import { makeSaleProfitability, makeSaleShow } from "./test/factories";

describe("Sales/Show", () => {
  it("renders the Shopify sale title and composed sections", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Sale HSCM#1746" })).toBeInTheDocument();
    expect(screen.getByText("Pikachu Figure")).toBeInTheDocument();
    expect(screen.getByText("Leave at the door")).toBeInTheDocument();
  });

  it("renders the WooCommerce sale title when the sale is only linked to Woo", () => {
    renderShow({
      shop_identifier: "WOO-1",
      shopify_id: "",
      shopify_name: "",
      woo_store_id: "WOO-1",
    });

    expect(screen.getByRole("heading", { name: "Sale WOO-1" })).toBeInTheDocument();
  });

  it("falls back to the local id in the title when the sale has no store identifiers", () => {
    renderShow({ shop_identifier: "", shopify_id: "", shopify_name: "", woo_store_id: "" });

    expect(screen.getByRole("heading", { name: "Sale 1" })).toBeInTheDocument();
  });

  it("renders no subtitle under the title, regardless of a payment plan", () => {
    const { container } = renderShow({
      payment_plans: [makeSalePaymentPlan({ is_origin_sale: false, sale_part_number: 2 })],
    });

    expect(container.querySelector("header h3")).not.toBeInTheDocument();
  });

  describe("follow-up payment presentation", () => {
    it("titles a follow-up payment as Payment, keeping the same identifier a sale would show", () => {
      renderShow({ is_follow_up_payment: true });

      expect(screen.getByRole("heading", { name: "Payment HSCM#1746" })).toBeInTheDocument();
      expect(screen.queryByRole("heading", { name: "Sale HSCM#1746" })).not.toBeInTheDocument();
    });

    it("strips the page down to what a follow-up payment actually knows", () => {
      renderShow({
        is_follow_up_payment: true,
        profitability: null,
        sale_items: [],
        shipping_address: undefined,
        billing_address: undefined,
        billing_differs_from_shipping: undefined,
        discount_total: undefined,
        shipping_total: undefined,
        payment_plans: [
          makeSalePaymentPlan({
            is_origin_sale: false,
            sale_part_number: 2,
            origin_sale: { path: "/sales/9", identifier: "HSCM#1745" },
          }),
        ],
      });

      expect(screen.queryByRole("article", { name: "Profit summary" })).not.toBeInTheDocument();
      expect(screen.queryByRole("table")).not.toBeInTheDocument();
      expect(screen.queryByRole("button", { name: /Shipping/ })).not.toBeInTheDocument();
      expect(screen.queryByRole("button", { name: /Billing/ })).not.toBeInTheDocument();
    });

    it("still shows the title, status, customer, total, identifiers, and place in the plan", () => {
      renderShow({
        is_follow_up_payment: true,
        payment_plans: [
          makeSalePaymentPlan({
            is_origin_sale: false,
            sale_part_number: 2,
            origin_sale: { path: "/sales/9", identifier: "HSCM#1745" },
          }),
        ],
      });

      expect(screen.getByRole("heading", { name: "Payment HSCM#1746" })).toBeInTheDocument();
      expect(screen.getByText("Processing")).toBeInTheDocument();
      const totalField = screen.getByText("Total", { selector: "dt" });
      expect(totalField.nextElementSibling).toHaveTextContent("1060");
      expect(screen.getByRole("link", { name: "HSCM#1745" })).toHaveAttribute("href", "/sales/9");
    });
  });

  it("shows the profit summary as a card of its own", () => {
    renderShow({ partially_paid: true, profitability: makeSaleProfitability() });

    const summary = screen.getByRole("article", { name: "Profit summary" });
    expect(within(summary).getByText("Gross Revenue")).toBeInTheDocument();
  });

  it("leaves the profit summary out when the sale makes no profit claim", () => {
    renderShow({ profitability: null });

    expect(screen.queryByRole("article", { name: "Profit summary" })).not.toBeInTheDocument();
  });

  it("routes a plan's sibling payments through Details rather than a top-of-page card", () => {
    renderShow({
      payment_plans: [
        makeSalePaymentPlan({
          expected_parts: 4,
          sale_part_number: 1,
          payments: [
            { sequence: 1, path: "/sales/1", identifier: "HSCM#1746", is_current_sale: true },
            { sequence: 2, path: "/sales/2", identifier: "HSCM#1747", is_current_sale: false },
          ],
        }),
      ],
    });

    expect(screen.getByRole("link", { name: "Payment 2 of 4 · HSCM#1747" })).toHaveAttribute(
      "href",
      "/sales/2",
    );
    expect(screen.getByText("Payment 1 of 4 · HSCM#1746 (this sale)")).toBeInTheDocument();
  });
});

function renderShow(overrides: Partial<ReturnType<typeof makeSaleShow>> = {}) {
  return render(<Show sale={makeSaleShow(overrides)} />);
}
