import { router } from "@inertiajs/react";
import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePagination, makeSalePaymentProgress } from "@/test/factories";

import Index from "./Index";
import { makeSaleIndexRecord } from "./test/factories";
import type { PaginationMeta, SaleIndexRecord, SaleSort, SalesFilters } from "./types";

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

  describe("search form", () => {
    it("applies a sort tab click immediately with the typed query and without the old page", async () => {
      const user = userEvent.setup();
      renderIndex({ pagination: makePagination({ current_page: 3, total_pages: 5 }) });

      await user.type(screen.getByRole("searchbox"), "dale");
      await user.click(screen.getByRole("tab", { name: "Oldest first" }));

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        { q: "dale", sort: "oldest" },
        expect.objectContaining({
          only: ["sales", "pagination", "search", "sort", "filters"],
          preserveState: true,
        }),
      );
    });

    it("applies the typed query with the Search button", async () => {
      const user = userEvent.setup();
      renderIndex({ sort: "oldest" });

      await user.type(screen.getByRole("searchbox"), "dale");
      await user.click(screen.getByRole("button", { name: /Search/ }));

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        { q: "dale", sort: "oldest" },
        expect.anything(),
      );
    });

    it("omits default settings from the request", async () => {
      const user = userEvent.setup();
      renderIndex({ search: { q: "dale" }, sort: "oldest" });

      await user.clear(screen.getByRole("searchbox"));
      await user.click(screen.getByRole("tab", { name: "Newest first" }));

      expect(router.get).toHaveBeenCalledWith("/sales", {}, expect.anything());
    });

    it("preserves the applied query and sort in both pagination areas", () => {
      renderIndex({
        pagination: makePagination({ current_page: 2, total_pages: 3 }),
        search: { q: "dale" },
        sort: "oldest",
      });

      const navigations = screen.getAllByRole("navigation", { name: "Pagination" });

      expect(navigations).toHaveLength(2);
      for (const navigation of navigations) {
        const hrefs = within(navigation)
          .getAllByRole("link")
          .map((link) => link.getAttribute("href"));

        expect(hrefs).toEqual([
          "/sales?page=1&q=dale&sort=oldest",
          "/sales?page=1&q=dale&sort=oldest",
          "/sales?page=3&q=dale&sort=oldest",
          "/sales?page=3&q=dale&sort=oldest",
        ]);
      }
    });

    it("keeps pagination links on the applied query while typing", async () => {
      const user = userEvent.setup();
      renderIndex({ pagination: makePagination({ current_page: 1, total_pages: 2 }) });

      await user.type(screen.getByRole("searchbox"), "dale");

      for (const link of screen.getAllByRole("link", { name: "Next" })) {
        expect(link).toHaveAttribute("href", "/sales?page=2");
      }
    });

    it("clears the search while keeping the applied sort", () => {
      renderIndex({ search: { q: "dale" }, sort: "oldest" });

      expect(screen.getByRole("link", { name: /Clear search/ })).toHaveAttribute(
        "href",
        "/sales?sort=oldest",
      );
    });

    it("offers no clear link for the default listing", () => {
      renderIndex();

      expect(screen.queryByRole("link", { name: /Clear search/ })).not.toBeInTheDocument();
    });

    it("offers no separate reset link", () => {
      renderIndex({ search: { q: "dale" }, sort: "oldest" });

      expect(screen.queryByRole("link", { name: "Reset" })).not.toBeInTheDocument();
    });

    it("marks the applied sort tab as selected and applies a new choice on click", async () => {
      const user = userEvent.setup();
      renderIndex({ sort: "oldest" });

      expect(screen.getByRole("tab", { name: "Oldest first" })).toHaveAttribute(
        "aria-selected",
        "true",
      );
      expect(screen.getByRole("tab", { name: "Newest first" })).toHaveAttribute(
        "aria-selected",
        "false",
      );

      await user.click(screen.getByRole("tab", { name: "Newest first" }));

      expect(screen.getByRole("tab", { name: "Newest first" })).toHaveAttribute(
        "aria-selected",
        "true",
      );
      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith("/sales", {}, expect.anything());
    });

    it("restores controls and the created marker when applied props change", () => {
      const { rerender } = renderIndex({ search: { q: "dale" } });
      expect(screen.getByRole("columnheader", { name: /Created/ })).toHaveTextContent("▾");

      rerender(
        indexElement({
          filters: { hide_partial_payments: true, show_missing_purchases: true },
          search: { q: "pikachu" },
          sort: "oldest",
        }),
      );

      expect(screen.getByRole("searchbox")).toHaveValue("pikachu");
      expect(screen.getByRole("tab", { name: "Oldest first" })).toHaveAttribute(
        "aria-selected",
        "true",
      );
      expect(screen.getByRole("checkbox", { name: "Hide Partial Payments" })).toBeChecked();
      expect(screen.getByRole("checkbox", { name: "Show Missing Purchases" })).toBeChecked();
      expect(screen.getByRole("columnheader", { name: /Created/ })).toHaveTextContent("▴");
    });

    it("keeps text typed while a sort request is pending when the response arrives", async () => {
      const user = userEvent.setup();
      const { rerender } = renderIndex();

      await user.click(screen.getByRole("tab", { name: "Oldest first" }));
      await user.type(screen.getByRole("searchbox"), "dale");
      rerender(indexElement({ sort: "oldest" }));

      expect(screen.getByRole("searchbox")).toHaveValue("dale");
      expect(screen.getByRole("searchbox")).toHaveFocus();
      expect(screen.getByRole("tab", { name: "Oldest first" })).toHaveAttribute(
        "aria-selected",
        "true",
      );
      expect(screen.getByRole("columnheader", { name: /Created/ })).toHaveTextContent("▴");
    });

    it("keeps the controls on an empty listing", () => {
      renderIndex({
        pagination: makePagination({ total_count: 0 }),
        sales: [],
        search: { q: "missing sale" },
        sort: "oldest",
      });

      expect(screen.getByRole("searchbox")).toHaveValue("missing sale");
      expect(screen.getByRole("tab", { name: "Oldest first" })).toHaveAttribute(
        "aria-selected",
        "true",
      );
      expect(screen.getByRole("button", { name: /Search/ })).toBeInTheDocument();
    });
  });

  describe("Hide Partial Payments filter", () => {
    const hidePartialPayments = { hide_partial_payments: true, show_missing_purchases: false };

    it("is unchecked by default and checked when the applied filter is on", () => {
      const { unmount } = renderIndex();
      expect(screen.getByRole("checkbox", { name: "Hide Partial Payments" })).not.toBeChecked();
      unmount();

      renderIndex({ filters: hidePartialPayments });
      expect(screen.getByRole("checkbox", { name: "Hide Partial Payments" })).toBeChecked();
    });

    it("applies the toggled filter immediately as 1 with the typed query", async () => {
      const user = userEvent.setup();
      renderIndex({ pagination: makePagination({ current_page: 2, total_pages: 3 }) });

      await user.type(screen.getByRole("searchbox"), "dale");
      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        { q: "dale", hide_partial_payments: "1" },
        expect.anything(),
      );
    });

    it("omits the filter from the request once unchecked", async () => {
      const user = userEvent.setup();
      renderIndex({ filters: hidePartialPayments });

      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));

      expect(router.get).toHaveBeenCalledWith("/sales", {}, expect.anything());
    });

    it("keeps the filter when clearing the search", () => {
      renderIndex({ filters: hidePartialPayments, search: { q: "dale" }, sort: "oldest" });

      expect(screen.getByRole("link", { name: /Clear search/ })).toHaveAttribute(
        "href",
        "/sales?sort=oldest&hide_partial_payments=1",
      );
    });

    it("keeps both pagination areas on the applied filter while a change is pending", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: hidePartialPayments,
        pagination: makePagination({ current_page: 1, total_pages: 2 }),
      });

      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));

      const nextLinks = screen.getAllByRole("link", { name: "Next" });
      expect(nextLinks).toHaveLength(2);
      for (const link of nextLinks) {
        expect(link).toHaveAttribute("href", "/sales?page=2&hide_partial_payments=1");
      }
    });

    it("shows Nothing found with usable controls when only the filter empties the listing", () => {
      renderIndex({
        filters: hidePartialPayments,
        pagination: makePagination({ total_count: 0 }),
        sales: [],
      });

      expect(screen.getByText("Nothing found")).toBeInTheDocument();
      expect(screen.getByRole("checkbox", { name: "Hide Partial Payments" })).toBeChecked();
      expect(screen.getByRole("button", { name: /Search/ })).toBeInTheDocument();
    });
  });

  describe("Show Missing Purchases filter", () => {
    const showMissingPurchases = { hide_partial_payments: false, show_missing_purchases: true };
    const bothFilters = { hide_partial_payments: true, show_missing_purchases: true };

    it("is unchecked by default and checked when the applied filter is on", () => {
      const { unmount } = renderIndex();
      expect(screen.getByRole("checkbox", { name: "Show Missing Purchases" })).not.toBeChecked();
      unmount();

      renderIndex({ filters: showMissingPurchases });
      expect(screen.getByRole("checkbox", { name: "Show Missing Purchases" })).toBeChecked();
    });

    it("sends every setting with each change so the last request carries the full form", async () => {
      const user = userEvent.setup();
      renderIndex({ pagination: makePagination({ current_page: 2, total_pages: 3 }) });

      await user.type(screen.getByRole("searchbox"), "dale");
      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));
      await user.click(screen.getByRole("checkbox", { name: "Show Missing Purchases" }));
      await user.click(screen.getByRole("tab", { name: "Oldest first" }));

      expect(router.get).toHaveBeenCalledTimes(3);
      expect(router.get).toHaveBeenLastCalledWith(
        "/sales",
        {
          q: "dale",
          sort: "oldest",
          hide_partial_payments: "1",
          show_missing_purchases: "1",
        },
        expect.anything(),
      );
    });

    it("keeps both flags and the sort when clearing the search", () => {
      renderIndex({ filters: bothFilters, search: { q: "dale" }, sort: "oldest" });

      expect(screen.getByRole("link", { name: /Clear search/ })).toHaveAttribute(
        "href",
        "/sales?sort=oldest&hide_partial_payments=1&show_missing_purchases=1",
      );
    });

    it("keeps both pagination areas on the applied state while changes are pending", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: showMissingPurchases,
        pagination: makePagination({ current_page: 1, total_pages: 2 }),
        search: { q: "dale" },
        sort: "oldest",
      });

      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));
      await user.click(screen.getByRole("checkbox", { name: "Show Missing Purchases" }));

      const nextLinks = screen.getAllByRole("link", { name: "Next" });
      expect(nextLinks).toHaveLength(2);
      for (const link of nextLinks) {
        expect(link).toHaveAttribute(
          "href",
          "/sales?page=2&q=dale&sort=oldest&show_missing_purchases=1",
        );
      }
    });

    it("shows Nothing found and keeps the form recoverable when only the filters empty the listing", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: bothFilters,
        pagination: makePagination({ total_count: 0 }),
        sales: [],
      });

      expect(screen.getByText("Nothing found")).toBeInTheDocument();

      await user.click(screen.getByRole("checkbox", { name: "Show Missing Purchases" }));

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        { hide_partial_payments: "1" },
        expect.anything(),
      );
      expect(screen.getByRole("checkbox", { name: "Hide Partial Payments" })).toBeChecked();
    });
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

function renderIndex(options: IndexOptions = {}) {
  return render(indexElement(options));
}

type IndexOptions = {
  sales?: SaleIndexRecord[];
  pagination?: PaginationMeta;
  search?: { q: string };
  sort?: SaleSort;
  filters?: SalesFilters;
  last_sync_time?: string | null;
};

function indexElement({
  sales = [makeSaleIndexRecord()],
  pagination = makePagination(),
  search = { q: "" },
  sort = "newest",
  filters = { hide_partial_payments: false, show_missing_purchases: false },
  last_sync_time = "20.05 at 10:00",
}: IndexOptions = {}) {
  return (
    <Index
      filters={filters}
      last_sync_time={last_sync_time}
      pagination={pagination}
      sales={sales}
      search={search}
      sort={sort}
    />
  );
}
