import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePagination, makeSalePaymentPlan } from "@/test/factories";

import Index from "./Index";
import { makeSaleIndexRecord } from "./test/factories";
import type { PaginationMeta, SaleIndexRecord } from "./types";

describe("Sales/Index", () => {
  it("renders the sales heading and add new record link", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Sales" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/sales/new",
    );
  });

  it("renders the sale customer and product title in the table", () => {
    renderIndex();

    expect(screen.getByText("Dale Cooper")).toBeInTheDocument();
    expect(screen.getByText("Pikachu Figure")).toBeInTheDocument();
  });

  it("renders a paginated row when plan context is missing", () => {
    const saleWithoutPlanContext = {
      ...makeSaleIndexRecord(),
      payment_plans: undefined,
    };

    expect(() => {
      // @ts-expect-error A stale partial response can omit this field at runtime.
      renderIndex({ sales: [saleWithoutPlanContext] });
    }).not.toThrow();
    expect(screen.getByText("Dale Cooper")).toBeInTheDocument();
  });

  it("renders a search form with the current query", () => {
    renderIndex({ search: { q: "dale" } });

    expect(screen.getByRole("searchbox")).toHaveValue("dale");
  });

  it("shows purchase item warehouse links instead of sale status text", () => {
    renderIndex();

    const warehouseLink = screen.getByRole("link", { name: /Berlin Hub/ });
    expect(warehouseLink).toHaveAttribute("href", "/purchase_items/101");
    expect(screen.queryByText("Processing")).not.toBeInTheDocument();
  });

  describe("payment plan affiliation", () => {
    it("marks the originating sale and states the position of its follow-up payment", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({
            payment_plans: [makeSalePaymentPlan({ collected_parts: 2 })],
          }),
          makeSaleIndexRecord({
            id: 2,
            payment_plans: [
              makeSalePaymentPlan({
                collected_parts: 3,
                is_origin_sale: false,
                sale_part_number: 2,
                origin_sale: { path: "/sales/1", identifier: "HSCM#1746" },
              }),
            ],
          }),
        ],
      });

      expect(screen.getByText("Payment plan · 2 of 8 collected")).toBeInTheDocument();
      expect(screen.getByText("Payment 2 of 8")).toBeInTheDocument();
      expect(screen.getByRole("link", { name: "Original sale HSCM#1746" })).toHaveAttribute(
        "href",
        "/sales/1",
      );
    });

    it("subordinates the follow-up row and leaves ordinary rows alone", () => {
      const { container } = renderIndex({
        sales: [
          makeSaleIndexRecord({
            payment_plans: [makeSalePaymentPlan({ collected_parts: 2 })],
          }),
          makeSaleIndexRecord({
            id: 2,
            payment_plans: [
              makeSalePaymentPlan({
                is_origin_sale: false,
                sale_part_number: 2,
                origin_sale: { path: "/sales/1", identifier: "HSCM#1746" },
              }),
            ],
          }),
        ],
      });

      const rows = container.querySelectorAll("tbody tr");
      expect(rows[0]).not.toHaveAttribute("data-follow-up");
      expect(rows[1]).toHaveAttribute("data-follow-up");
    });

    it("shows a deposit projection without rendering one of one", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({
            payment_plans: [
              makeSalePaymentPlan({
                kind: "deposit",
                expected_parts: 1,
                collected_parts: 1,
                deposit_percent: 30,
                projected_total: "1 020 EUR",
              }),
            ],
          }),
        ],
      });

      expect(
        screen.getByText(/30% deposit collected · Projected total 1\s020 EUR/),
      ).toBeInTheDocument();
      expect(screen.queryByText(/1 of 1/)).not.toBeInTheDocument();
    });
  });

  it("renders an empty state when a search has no matches", () => {
    renderIndex({
      pagination: makePagination({ total_count: 0 }),
      sales: [],
      search: { q: "missing sale" },
    });

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
  });

  describe("Store Sync dialog", () => {
    it("renders the Store Sync button", () => {
      renderIndex();

      expect(screen.getByRole("button", { name: "Store Sync" })).toBeInTheDocument();
    });

    it("opens the dialog when Store Sync is clicked", async () => {
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Sales Synchronization")).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Everything" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Last 100 Sales" })).toBeInTheDocument();
      expect(screen.getByRole("link", { name: "Track Jobs Progress" })).toBeInTheDocument();
    });

    it("shows the last sync time when last_sync_time is provided", async () => {
      const user = userEvent.setup();
      renderIndex({ last_sync_time: "20.05 at 10:00" });

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Last sync: 20.05 at 10:00")).toBeInTheDocument();
    });

    it("closes the dialog when Close is clicked", async () => {
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Store Sync" }));
      await user.click(screen.getByRole("button", { name: "Close" }));

      expect(screen.queryByText("Sales Synchronization")).not.toBeInTheDocument();
    });
  });
});

function renderIndex({
  sales = [makeSaleIndexRecord()],
  pagination = makePagination(),
  search = { q: "" },
  last_sync_time = "20.05 at 10:00",
}: {
  sales?: SaleIndexRecord[];
  pagination?: PaginationMeta;
  search?: { q: string };
  last_sync_time?: string | null;
} = {}) {
  return render(
    <Index last_sync_time={last_sync_time} pagination={pagination} sales={sales} search={search} />,
  );
}
