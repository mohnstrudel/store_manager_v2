import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePagination, makeSalePaymentProgress } from "@/test/factories";

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

  describe("payment progress marker", () => {
    it("shows scheduled payment progress before the sale details", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({
            settlement_status: "not_fully_paid",
            payment_progress: makeSalePaymentProgress({
              source: "plan_schedule",
              percent: 42,
              sale_part_number: 2,
              expected_parts: 8,
              total: "$245",
            }),
          }),
        ],
      });

      const marker = screen.getByText("Payment 2 of 8 · 42% collected · Projected total $245");
      expect(marker.parentElement?.firstElementChild).toBe(marker);
    });

    it("shows deposit progress without a fabricated part count", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({
            settlement_status: "not_fully_paid",
            payment_progress: makeSalePaymentProgress({
              source: "plan_deposit",
              percent: 42,
              total: "$245",
            }),
          }),
        ],
      });

      expect(
        screen.getByText("Deposit · 42% collected · Projected total $245"),
      ).toBeInTheDocument();
      expect(screen.queryByText(/1 of 1/)).not.toBeInTheDocument();
    });

    it("shows amount-only progress", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({
            settlement_status: "not_fully_paid",
            payment_progress: makeSalePaymentProgress({
              source: "amount",
              percent: 42,
              total: "$245",
            }),
          }),
        ],
      });

      expect(screen.getByText("Not fully paid · 42% collected · Total $245")).toBeInTheDocument();
    });

    it("shows a verified Woo deposit without a percentage", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({
            settlement_status: "not_fully_paid",
            payment_progress: makeSalePaymentProgress({
              source: "woo_deposit",
              paid: "$196",
              total: "$1,145",
            }),
          }),
        ],
      });

      expect(
        screen.getByText("Not fully paid · Deposit $196 collected · Total $1,145"),
      ).toBeInTheDocument();
      expect(screen.queryByText(/% collected/)).not.toBeInTheDocument();
    });

    it("shows unavailable Woo payment amounts without a percentage", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({
            settlement_status: "not_fully_paid",
            payment_progress: makeSalePaymentProgress({
              source: "woo_unavailable",
              total: "$1,145",
            }),
          }),
        ],
      });

      expect(screen.getByText("Not fully paid · Payment amounts unavailable")).toBeInTheDocument();
      expect(screen.queryByText(/% collected/)).not.toBeInTheDocument();
    });

    it("uses the backend-owned follow-up classification", () => {
      const { container } = renderIndex({
        sales: [makeSaleIndexRecord(), makeSaleIndexRecord({ id: 2, is_follow_up_payment: true })],
      });

      const rows = container.querySelectorAll("tbody tr");
      expect(rows[0]).not.toHaveAttribute("data-follow-up");
      expect(rows[1]).toHaveAttribute("data-follow-up");
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
