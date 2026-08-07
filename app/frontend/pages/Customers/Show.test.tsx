import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Show from "./Show";
import { makeSalePaymentPlan } from "@/test/factories";
import { makeCustomerDetail, makeCustomerSale } from "./test/factories";
import type { CustomerDetailRecord, SaleRecord } from "./types";

describe("Customers/Show", () => {
  it("renders customer details and heading", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Dale Cooper" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "dale@fbi.gov" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/customers/1/edit");
  });

  it("renders sales when present", () => {
    renderShow({
      active_sales: [
        makeCustomerSale({
          active: true,
          id: 9,
          path: "/sales/9",
          sale_identifier: "HSCM#1957",
          sold_product_name: "Twin Peaks Coffee",
          status: "active",
          total: "50.00",
        }),
      ],
      completed_sales: [makeCustomerSale()],
    });

    expect(screen.getByRole("heading", { name: "Active Sales" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Completed Sales" })).toBeInTheDocument();
    expect(
      screen.getByRole("img", {
        name: "Image unavailable for Twin Peaks Cherry Pie",
      }),
    ).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Twin Peaks Cherry Pie HSCM#1958" })).toHaveAttribute(
      "href",
      "/sales/10",
    );
    expect(screen.getByText("Twin Peaks Cherry Pie")).toHaveClass("group-hover:text-blue-600");
    expect(screen.getByText("Completed")).toBeInTheDocument();
  });

  it("marks a follow-up payment so it does not read as a duplicate order", () => {
    renderShow({
      active_sales: [
        makeCustomerSale({ id: 9, path: "/sales/9", sale_identifier: "HSCM#1746" }),
        makeCustomerSale({
          id: 10,
          path: "/sales/10",
          sale_identifier: "HSCM#1747",
          payment_plans: [
            makeSalePaymentPlan({
              expected_parts: 4,
              is_origin_sale: false,
              sale_part_number: 2,
              origin_sale: { path: "/sales/9", identifier: "HSCM#1746" },
            }),
          ],
        }),
      ],
      completed_sales: [],
    });

    expect(screen.getByText("Payment 2 of 4")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Original sale HSCM#1746" })).toHaveAttribute(
      "href",
      "/sales/9",
    );

    const salesSection = screen.getByRole("heading", { name: "Active Sales" }).closest("section");
    const rows = salesSection!.querySelectorAll("tbody tr");
    expect(rows[0]).not.toHaveAttribute("data-follow-up");
    expect(rows[1]).toHaveAttribute("data-follow-up");
  });

  it("names a follow-up payment 'Payment' instead of 'Sale' when there is no sold product name", () => {
    renderShow({
      active_sales: [
        makeCustomerSale({
          id: 10,
          path: "/sales/10",
          sale_identifier: "HSCM#1747",
          sold_product_name: "",
          is_follow_up_payment: true,
        }),
      ],
      completed_sales: [],
    });

    expect(
      screen.getByRole("img", { name: "Image unavailable for Payment HSCM#1747" }),
    ).toBeInTheDocument();
  });

  it("hides the sales sections when there are no sales", () => {
    renderShow({ active_sales: [], completed_sales: [] });

    expect(screen.queryByRole("heading", { name: "Active Sales" })).not.toBeInTheDocument();
    expect(screen.queryByRole("heading", { name: "Completed Sales" })).not.toBeInTheDocument();
  });

  describe("destroy", () => {
    it("destroys the customer after confirmation", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(true);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this customer" }));

      expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
      expect(router.delete).toHaveBeenCalledWith("/customers/1");
    });

    it("does not destroy the customer when confirmation is dismissed", async () => {
      const user = userEvent.setup();
      vi.spyOn(window, "confirm").mockReturnValue(false);
      renderShow();

      await user.click(screen.getByRole("button", { name: "Destroy this customer" }));

      expect(router.delete).not.toHaveBeenCalled();
    });
  });
});

function renderShow({
  active_sales = [],
  completed_sales = [],
  customer = makeCustomerDetail(),
}: {
  active_sales?: SaleRecord[];
  completed_sales?: SaleRecord[];
  customer?: CustomerDetailRecord;
} = {}) {
  return render(
    <Show active_sales={active_sales} completed_sales={completed_sales} customer={customer} />,
  );
}
