import { router } from "@inertiajs/react";
import { render, screen, within } from "@testing-library/react";
import userEvent, { type UserEvent } from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePagination, makeSalePaymentProgress } from "@/test/factories";
import { nextFormErrors } from "@/test/mocks/inertia";
import type { SalesTagRecord } from "@/types/salesTag";

import Index from "./Index";
import { makeSaleIndexRecord } from "./test/factories";
import type { PaginationMeta, SaleIndexRecord, SaleSort, SalesFilters } from "./types";

const tagColors = ["green", "pink", "sky", "violet", "olive"] as const;

describe("Sales/Index", () => {
  it("renders the sales heading and add new record link", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Sales" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/sales/new",
    );
  });

  it("links to Broken Sales before Tags when the user can open it", () => {
    renderIndex();

    const broken = screen.getByRole("link", { name: "Broken" });
    const tags = screen.getByRole("link", { name: "Tags" });

    expect(broken).toHaveAttribute("href", "/broken_sales");
    expect(broken.compareDocumentPosition(tags) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy();
  });

  it("hides Broken Sales from users who cannot open it", () => {
    renderIndex({ can_view_broken_sales: false });

    expect(screen.queryByRole("link", { name: "Broken" })).not.toBeInTheDocument();
  });

  it.each([
    [1, "Broken, 1 problem", "1"],
    [99, "Broken, 99 problems", "99"],
    [100, "Broken, 100 problems", "99+"],
    [225, "Broken, 225 problems", "99+"],
  ])("badges the Broken link with %i problems", (count, name, badgeText) => {
    renderIndex({ broken_problem_count: count });

    const broken = screen.getByRole("link", { name });
    const badge = broken.querySelector(".nav_menu_badge");
    expect(broken).toHaveAttribute("href", "/broken_sales");
    expect(badge).toHaveTextContent(badgeText);
    expect(badge).toHaveAttribute("aria-hidden", "true");
  });

  it("shows no badge on the Broken link when nothing is broken", () => {
    renderIndex({ broken_problem_count: 0 });

    const broken = screen.getByRole("link", { name: "Broken" });
    expect(broken.querySelector(".nav_menu_badge")).toBeNull();
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

  describe("unlinked Shopify variant mark", () => {
    it("marks a sale whose Shopify variant has no match with a link to the Shopify conflicts", () => {
      renderIndex({ sales: [makeSaleIndexRecord({ shopify_variant_unlinked: true })] });

      const mark = screen.getByRole("link", { name: "BROKEN" });
      expect(mark).toHaveAttribute("href", "/broken_sales?issue_type=shopify_conflicts");
      expect(mark).toHaveAttribute(
        "title",
        "Shopify variant has no match here. Fix it in Broken Sales.",
      );
    });

    it("marks only the affected sale", () => {
      renderIndex({
        sales: [
          makeSaleIndexRecord({ id: 1, shopify_variant_unlinked: true }),
          makeSaleIndexRecord({ id: 2, shopify_variant_unlinked: false }),
        ],
      });

      expect(screen.getAllByRole("link", { name: "BROKEN" })).toHaveLength(1);
    });

    it("shows no mark when every Shopify variant is linked or absent", () => {
      renderIndex({ sales: [makeSaleIndexRecord({ shopify_variant_unlinked: false })] });

      expect(screen.queryByRole("link", { name: "BROKEN" })).not.toBeInTheDocument();
    });

    it("does not open the sale when the mark is used", async () => {
      const user = userEvent.setup();
      renderIndex({ sales: [makeSaleIndexRecord({ shopify_variant_unlinked: true })] });

      await user.click(screen.getByRole("link", { name: "BROKEN" }));

      expect(router.visit).not.toHaveBeenCalled();
    });
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
      await user.click(screen.getByRole("button", { name: "Oldest first" }));

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        { q: "dale", sort: "oldest" },
        expect.objectContaining({
          only: [
            "sales",
            "pagination",
            "search",
            "sort",
            "filters",
            "tag_options",
            "tag_colors",
            "can_tag_sales",
            "flash",
          ],
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
      await user.click(screen.getByRole("button", { name: "Newest first" }));

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

    it("clears the search while keeping the applied sort", async () => {
      const user = userEvent.setup();
      renderIndex({ search: { q: "dale" }, sort: "oldest" });

      await user.click(screen.getByRole("button", { name: /Clear search/ }));

      expect(router.get).toHaveBeenLastCalledWith("/sales", { sort: "oldest" }, expect.anything());
    });

    it("clears the search with the latest filter choice", async () => {
      const user = userEvent.setup();
      renderIndex({ search: { q: "dale" } });

      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));
      await user.click(screen.getByRole("button", { name: /Clear search/ }));

      expect(router.get).toHaveBeenLastCalledWith(
        "/sales",
        { hide_partial_payments: "1" },
        expect.anything(),
      );
    });

    it("offers no clear link for the default listing", () => {
      renderIndex();

      expect(screen.queryByRole("button", { name: /Clear search/ })).not.toBeInTheDocument();
    });

    it("offers no separate reset link", () => {
      renderIndex({ search: { q: "dale" }, sort: "oldest" });

      expect(screen.queryByRole("link", { name: "Reset" })).not.toBeInTheDocument();
    });

    it("marks the applied sort tab as selected and applies a new choice on click", async () => {
      const user = userEvent.setup();
      renderIndex({ sort: "oldest" });

      expect(screen.getByRole("button", { name: "Oldest first" })).toHaveAttribute(
        "aria-pressed",
        "true",
      );
      expect(screen.getByRole("button", { name: "Newest first" })).toHaveAttribute(
        "aria-pressed",
        "false",
      );

      await user.click(screen.getByRole("button", { name: "Newest first" }));

      expect(screen.getByRole("button", { name: "Newest first" })).toHaveAttribute(
        "aria-pressed",
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
          filters: { hide_partial_payments: true, missing_purchases_only: true, tag_id: null },
          search: { q: "pikachu" },
          sort: "oldest",
        }),
      );

      expect(screen.getByRole("searchbox")).toHaveValue("pikachu");
      expect(screen.getByRole("button", { name: "Oldest first" })).toHaveAttribute(
        "aria-pressed",
        "true",
      );
      expect(screen.getByRole("checkbox", { name: "Hide Partial Payments" })).toBeChecked();
      expect(screen.getByRole("checkbox", { name: "Missing Purchases Only" })).toBeChecked();
      expect(screen.getByRole("columnheader", { name: /Created/ })).toHaveTextContent("▴");
    });

    it("keeps text typed while a sort request is pending when the response arrives", async () => {
      const user = userEvent.setup();
      const { rerender } = renderIndex();

      await user.click(screen.getByRole("button", { name: "Oldest first" }));
      await user.type(screen.getByRole("searchbox"), "dale");
      rerender(indexElement({ sort: "oldest" }));

      expect(screen.getByRole("searchbox")).toHaveValue("dale");
      expect(screen.getByRole("searchbox")).toHaveFocus();
      expect(screen.getByRole("button", { name: "Oldest first" })).toHaveAttribute(
        "aria-pressed",
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
      expect(screen.getByRole("button", { name: "Oldest first" })).toHaveAttribute(
        "aria-pressed",
        "true",
      );
      expect(screen.getByRole("button", { name: /Search/ })).toBeInTheDocument();
    });
  });

  describe("Hide Partial Payments filter", () => {
    const hidePartialPayments = {
      hide_partial_payments: true,
      missing_purchases_only: false,
      tag_id: null,
    };

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

    it("keeps the filter when clearing the search", async () => {
      const user = userEvent.setup();
      renderIndex({ filters: hidePartialPayments, search: { q: "dale" }, sort: "oldest" });

      await user.click(screen.getByRole("button", { name: /Clear search/ }));

      expect(router.get).toHaveBeenLastCalledWith(
        "/sales",
        { sort: "oldest", hide_partial_payments: "1" },
        expect.anything(),
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

  describe("Missing Purchases Only filter", () => {
    const missingPurchasesOnly = {
      hide_partial_payments: false,
      missing_purchases_only: true,
      tag_id: null,
    };
    const bothFilters = { hide_partial_payments: true, missing_purchases_only: true, tag_id: null };

    it("is unchecked by default and checked when the applied filter is on", () => {
      const { unmount } = renderIndex();
      expect(screen.getByRole("checkbox", { name: "Missing Purchases Only" })).not.toBeChecked();
      unmount();

      renderIndex({ filters: missingPurchasesOnly });
      expect(screen.getByRole("checkbox", { name: "Missing Purchases Only" })).toBeChecked();
    });

    it("sends every setting with each change so the last request carries the full form", async () => {
      const user = userEvent.setup();
      renderIndex({ pagination: makePagination({ current_page: 2, total_pages: 3 }) });

      await user.type(screen.getByRole("searchbox"), "dale");
      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));
      await user.click(screen.getByRole("checkbox", { name: "Missing Purchases Only" }));
      await user.click(screen.getByRole("button", { name: "Oldest first" }));

      expect(router.get).toHaveBeenCalledTimes(3);
      expect(router.get).toHaveBeenLastCalledWith(
        "/sales",
        {
          q: "dale",
          sort: "oldest",
          hide_partial_payments: "1",
          missing_purchases_only: "1",
        },
        expect.anything(),
      );
    });

    it("keeps both flags and the sort when clearing the search", async () => {
      const user = userEvent.setup();
      renderIndex({ filters: bothFilters, search: { q: "dale" }, sort: "oldest" });

      await user.click(screen.getByRole("button", { name: /Clear search/ }));

      expect(router.get).toHaveBeenLastCalledWith(
        "/sales",
        { sort: "oldest", hide_partial_payments: "1", missing_purchases_only: "1" },
        expect.anything(),
      );
    });

    it("keeps both pagination areas on the applied state while changes are pending", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: missingPurchasesOnly,
        pagination: makePagination({ current_page: 1, total_pages: 2 }),
        search: { q: "dale" },
        sort: "oldest",
      });

      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));
      await user.click(screen.getByRole("checkbox", { name: "Missing Purchases Only" }));

      const nextLinks = screen.getAllByRole("link", { name: "Next" });
      expect(nextLinks).toHaveLength(2);
      for (const link of nextLinks) {
        expect(link).toHaveAttribute(
          "href",
          "/sales?page=2&q=dale&sort=oldest&missing_purchases_only=1",
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

      await user.click(screen.getByRole("checkbox", { name: "Missing Purchases Only" }));

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        { hide_partial_payments: "1" },
        expect.anything(),
      );
      expect(screen.getByRole("checkbox", { name: "Hide Partial Payments" })).toBeChecked();
    });
  });

  describe("Tag filter", () => {
    const vip: SalesTagRecord = { id: 2, name: "VIP", color: "sky" };
    const rush: SalesTagRecord = { id: 4, name: "Rush", color: "pink" };
    const noFilters = { hide_partial_payments: false, missing_purchases_only: false, tag_id: null };
    const vipFilters = { ...noFilters, tag_id: vip.id };
    const bothFiltersWithVip = {
      ...vipFilters,
      hide_partial_payments: true,
      missing_purchases_only: true,
    };

    it("offers a Filter by tag button after the last filter and no badge until a tag is applied", () => {
      renderIndex({ tag_options: [rush, vip] });

      expect(
        within(tagFilter()).getByRole("button", { name: "Filter by tag" }),
      ).toBeInTheDocument();
      expect(
        within(tagFilter()).queryByRole("button", { name: /^Remove / }),
      ).not.toBeInTheDocument();
    });

    it("shows the applied tag as a removable badge beside the button", () => {
      renderIndex({ filters: vipFilters, tag_options: [rush, vip] });

      expect(
        within(tagFilter()).getByRole("button", { name: "Remove VIP from the tag filter" }),
      ).toHaveTextContent("VIP");
      expect(
        within(tagFilter()).getByRole("button", { name: "Filter by tag" }),
      ).toBeInTheDocument();
    });

    it("removes the filter when the applied tag is clicked, keeping the other settings", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: bothFiltersWithVip,
        pagination: makePagination({ current_page: 2, total_pages: 3 }),
        search: { q: "dale" },
        sort: "oldest",
        tag_options: [rush, vip],
      });

      await user.click(
        within(tagFilter()).getByRole("button", { name: "Remove VIP from the tag filter" }),
      );

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        { q: "dale", sort: "oldest", hide_partial_payments: "1", missing_purchases_only: "1" },
        expect.objectContaining({ preserveState: true }),
      );
      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    });

    it("opens the shared tag dialog with the applied tag checked", async () => {
      const user = userEvent.setup();
      renderIndex({ filters: vipFilters, tag_options: [rush, vip] });

      const dialog = await openTagFilter(user);

      expect(within(dialog).getByRole("checkbox", { name: "VIP" })).toBeChecked();
      expect(within(dialog).getByRole("checkbox", { name: "Rush" })).not.toBeChecked();
      expect(within(dialog).getByRole("searchbox", { name: "Filter tags" })).toBeInTheDocument();
      expect(router.get).not.toHaveBeenCalled();
    });

    it("applies the chosen tag with the full form and without the old page", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: { ...noFilters, hide_partial_payments: true, missing_purchases_only: true },
        pagination: makePagination({ current_page: 2, total_pages: 3 }),
        search: { q: "dale" },
        sort: "oldest",
        tag_options: [rush, vip],
      });

      const dialog = await openTagFilter(user);
      await user.click(within(dialog).getByRole("checkbox", { name: "VIP" }));
      await user.click(within(dialog).getByRole("button", { name: "Apply filter" }));

      expect(router.get).toHaveBeenCalledTimes(1);
      expect(router.get).toHaveBeenCalledWith(
        "/sales",
        {
          q: "dale",
          sort: "oldest",
          hide_partial_payments: "1",
          missing_purchases_only: "1",
          tag_id: "2",
        },
        expect.objectContaining({ preserveState: true }),
      );
      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
    });

    it("keeps one tag: choosing another replaces the previous choice", async () => {
      const user = userEvent.setup();
      renderIndex({ filters: vipFilters, tag_options: [rush, vip] });

      const dialog = await openTagFilter(user);
      await user.click(within(dialog).getByRole("checkbox", { name: "Rush" }));

      expect(within(dialog).getByRole("checkbox", { name: "Rush" })).toBeChecked();
      expect(within(dialog).getByRole("checkbox", { name: "VIP" })).not.toBeChecked();

      await user.click(within(dialog).getByRole("button", { name: "Apply filter" }));

      expect(router.get).toHaveBeenCalledWith("/sales", { tag_id: "4" }, expect.anything());
    });

    it("omits tag_id once the tag is unchecked and applied, keeping the other settings", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: bothFiltersWithVip,
        search: { q: "dale" },
        sort: "oldest",
        tag_options: [rush, vip],
      });

      const dialog = await openTagFilter(user);
      await user.click(within(dialog).getByRole("checkbox", { name: "VIP" }));
      await user.click(within(dialog).getByRole("button", { name: "Apply filter" }));

      expect(router.get).toHaveBeenLastCalledWith(
        "/sales",
        { q: "dale", sort: "oldest", hide_partial_payments: "1", missing_purchases_only: "1" },
        expect.anything(),
      );
    });

    it("applies nothing when the dialog is cancelled and starts from the applied tag next time", async () => {
      const user = userEvent.setup();
      renderIndex({ filters: vipFilters, tag_options: [rush, vip] });

      const dialog = await openTagFilter(user);
      await user.click(within(dialog).getByRole("checkbox", { name: "Rush" }));
      await user.click(within(dialog).getByRole("button", { name: "Cancel" }));

      expect(router.get).not.toHaveBeenCalled();
      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();

      const reopened = await openTagFilter(user);
      expect(within(reopened).getByRole("checkbox", { name: "VIP" })).toBeChecked();
      expect(within(reopened).getByRole("checkbox", { name: "Rush" })).not.toBeChecked();
    });

    it("keeps the tag when the search is cleared or another setting changes", async () => {
      const user = userEvent.setup();
      renderIndex({ filters: vipFilters, search: { q: "dale" }, tag_options: [rush, vip] });

      await user.click(screen.getByRole("button", { name: /Clear search/ }));
      expect(router.get).toHaveBeenLastCalledWith("/sales", { tag_id: "2" }, expect.anything());

      await user.click(screen.getByRole("checkbox", { name: "Hide Partial Payments" }));
      expect(router.get).toHaveBeenLastCalledWith(
        "/sales",
        { hide_partial_payments: "1", tag_id: "2" },
        expect.anything(),
      );
    });

    it("keeps both pagination areas on the applied tag", () => {
      renderIndex({
        filters: vipFilters,
        pagination: makePagination({ current_page: 1, total_pages: 2 }),
        search: { q: "dale" },
        tag_options: [rush, vip],
      });

      const nextLinks = screen.getAllByRole("link", { name: "Next" });
      expect(nextLinks).toHaveLength(2);
      for (const link of nextLinks) {
        expect(link).toHaveAttribute("href", "/sales?page=2&q=dale&tag_id=2");
      }
    });

    it("shows Nothing found with the tag still clearable when only the tag empties the listing", async () => {
      const user = userEvent.setup();
      renderIndex({
        filters: vipFilters,
        pagination: makePagination({ total_count: 0 }),
        sales: [],
        tag_options: [rush, vip],
      });

      expect(screen.getByText("Nothing found")).toBeInTheDocument();
      const dialog = await openTagFilter(user);
      await user.click(within(dialog).getByRole("checkbox", { name: "VIP" }));
      await user.click(within(dialog).getByRole("button", { name: "Apply filter" }));

      expect(router.get).toHaveBeenCalledWith("/sales", {}, expect.anything());
    });

    it("drops the badge when the applied props drop the tag", () => {
      const { rerender } = renderIndex({ filters: vipFilters, tag_options: [rush, vip] });
      expect(within(tagFilter()).getByText("VIP")).toBeInTheDocument();

      rerender(indexElement({ tag_options: [rush] }));

      expect(within(tagFilter()).queryByText("VIP")).not.toBeInTheDocument();
      expect(
        within(tagFilter()).queryByRole("button", { name: /^Remove / }),
      ).not.toBeInTheDocument();
    });

    it("keeps text typed while a tag request is pending when the response arrives", async () => {
      const user = userEvent.setup();
      const { rerender } = renderIndex({ tag_options: [rush, vip] });

      const dialog = await openTagFilter(user);
      await user.click(within(dialog).getByRole("checkbox", { name: "VIP" }));
      await user.click(within(dialog).getByRole("button", { name: "Apply filter" }));
      await user.type(screen.getByRole("searchbox", { name: "Search sales" }), "dale");
      rerender(indexElement({ filters: vipFilters, tag_options: [rush, vip] }));

      expect(screen.getByRole("searchbox", { name: "Search sales" })).toHaveValue("dale");
      expect(screen.getByRole("searchbox", { name: "Search sales" })).toHaveFocus();
      expect(within(tagFilter()).getByText("VIP")).toBeInTheDocument();
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

  describe("Tags column", () => {
    const rush: SalesTagRecord = { id: 4, name: "Rush", color: "pink" };
    const vip: SalesTagRecord = { id: 2, name: "VIP", color: "sky" };
    const wholesale: SalesTagRecord = { id: 9, name: "Wholesale", color: "green" };
    const catalog = [rush, vip, wholesale];
    const tagsPath = "/sales/1/tags";
    const reloadedProps = [
      "sales",
      "pagination",
      "filters",
      "tag_options",
      "tag_colors",
      "can_tag_sales",
      "flash",
    ];

    function renderTagged(tags: SalesTagRecord[] = [vip], options: IndexOptions = {}) {
      return renderIndex({
        sales: [makeSaleIndexRecord({ tags })],
        tag_options: catalog,
        ...options,
      });
    }

    it("sits third, after Customer + Products and before Purchase Status", () => {
      renderTagged();

      const headers = screen.getAllByRole("columnheader").map((header) => header.textContent);

      expect(headers.slice(0, 4)).toEqual([
        "Image",
        "Customer + Products",
        "Tags",
        "Purchase Status",
      ]);
    });

    it("shows the given tags as badges in the given order", () => {
      const { container } = renderTagged([rush, vip]);

      const badges = Array.from(container.querySelectorAll(".sales_tags li"));

      expect(badges.map((badge) => badge.textContent)).toEqual(["Rush", "VIP"]);
    });

    it("offers a quiet Edit control and no empty list for an untagged sale", () => {
      const { container } = renderTagged([]);

      expect(screen.getByRole("button", { name: "Edit" })).toBeInTheDocument();
      expect(container.querySelector(".sales_tags")).not.toBeInTheDocument();
    });

    it("shows badges without an editor for users who cannot tag sales", () => {
      renderTagged([vip], { can_tag_sales: false });

      expect(screen.getByText("VIP")).toBeInTheDocument();
      expect(screen.queryByRole("button", { name: "Edit" })).not.toBeInTheDocument();
    });

    it("opens the shared tags dialog from the Edit control", async () => {
      const user = userEvent.setup();
      renderTagged([vip]);

      const dialog = await openEditor(user);

      expect(within(dialog).getByRole("checkbox", { name: "VIP" })).toBeChecked();
      expect(within(dialog).getByRole("checkbox", { name: "Rush" })).not.toBeChecked();
    });

    it("keeps the saved badges in the cell while the dialog edits a draft", async () => {
      const user = userEvent.setup();
      const { container } = renderTagged([vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));

      const badges = Array.from(container.querySelectorAll(".inline_cell_display .sales_tag"));
      expect(badges.map((badge) => badge.textContent)).toEqual(["VIP"]);
    });

    it("titles the dialog Add tags for an untagged sale", async () => {
      const user = userEvent.setup();
      renderTagged([]);

      await user.click(screen.getByRole("button", { name: "Edit" }));

      expect(await screen.findByRole("dialog", { name: "Add tags" })).toBeInTheDocument();
    });

    it("saves the draft with the marker, original ids and the current page as return target", async () => {
      const user = userEvent.setup();
      renderTagged([vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(router.patch).toHaveBeenCalledTimes(1);
      expect(router.patch).toHaveBeenCalledWith(
        tagsPath,
        {
          sale: { tagging: { submitted: "1", ids: [2, 4], original_ids: [2] } },
          return_to: "/",
        },
        expect.objectContaining({ only: reloadedProps, preserveScroll: true }),
      );
    });

    it("clears all tags by unchecking them and sending the original ids", async () => {
      const user = userEvent.setup();
      renderTagged([rush, vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("checkbox", { name: "VIP" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(router.patch).toHaveBeenCalledWith(
        tagsPath,
        {
          sale: { tagging: { submitted: "1", ids: [], original_ids: [4, 2] } },
          return_to: "/",
        },
        expect.anything(),
      );
    });

    it("closes the dialog once the save is confirmed", async () => {
      const user = userEvent.setup();
      renderTagged([vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(screen.queryByRole("dialog")).not.toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Edit" })).toBeInTheDocument();
    });

    it("discards the draft on Cancel without sending anything", async () => {
      const user = userEvent.setup();
      renderTagged([vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Cancel" }));

      expect(router.patch).not.toHaveBeenCalled();
      await openEditor(user);
      expect(screen.getByRole("checkbox", { name: "Rush" })).not.toBeChecked();
    });

    it("keeps the draft and shows the error after an ordinary rejection", async () => {
      const user = userEvent.setup();
      nextFormErrors.mockReturnValueOnce({ tags: "Name is too long (maximum is 30 characters)" });
      renderTagged([vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(screen.getByText("Name is too long (maximum is 30 characters)")).toBeInTheDocument();
      expect(screen.getByRole("checkbox", { name: "Rush" })).toBeChecked();
      expect(screen.queryByRole("button", { name: /Reload tags/ })).not.toBeInTheDocument();
    });

    it.each([
      "Tags changed since you opened this editor. Reload tags and try again.",
      "A selected tag is no longer available. Reload tags and try again.",
    ])("offers an explicit reload that discards the draft after: %s", async (message) => {
      const user = userEvent.setup();
      nextFormErrors.mockReturnValueOnce({ tags: message });
      renderTagged([vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("button", { name: "Save" }));
      expect(router.reload).not.toHaveBeenCalled();

      await user.click(screen.getByRole("button", { name: "Reload tags (discards your changes)" }));

      expect(router.reload).toHaveBeenCalledWith(expect.objectContaining({ only: reloadedProps }));
    });

    it.each([
      "Tags changed since you opened this editor. Reload tags and try again.",
      "A selected tag is no longer available. Reload tags and try again.",
    ])(
      "keeps the draft and the error through further selection until Reload is chosen after: %s",
      async (message) => {
        const user = userEvent.setup();
        nextFormErrors.mockReturnValueOnce({ tags: message });
        renderTagged([vip]);

        await openEditor(user);
        await user.click(screen.getByRole("checkbox", { name: "Rush" }));
        await user.click(screen.getByRole("button", { name: "Save" }));
        await user.click(screen.getByRole("checkbox", { name: "Wholesale" }));

        expect(screen.getByText(message)).toBeInTheDocument();
        expect(
          screen.getByRole("button", { name: "Reload tags (discards your changes)" }),
        ).toBeInTheDocument();
        expect(screen.getByRole("checkbox", { name: "Rush" })).toBeChecked();
        expect(screen.getByRole("checkbox", { name: "Wholesale" })).toBeChecked();
      },
    );

    it("does not open the sale when the cell or the dialog is used", async () => {
      const user = userEvent.setup();
      renderTagged([vip]);

      await openEditor(user);
      await user.click(screen.getByRole("checkbox", { name: "Rush" }));
      await user.click(screen.getByRole("heading", { name: "Edit tags" }));
      screen.getByRole("checkbox", { name: "Rush" }).focus();
      await user.keyboard("{Enter}");

      expect(screen.getByRole("dialog", { name: "Edit tags" })).toBeInTheDocument();
      expect(router.patch).not.toHaveBeenCalled();

      await user.click(screen.getByRole("button", { name: "Cancel" }));
      await user.click(screen.getByText("VIP"));

      expect(router.visit).not.toHaveBeenCalled();
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
  tag_options?: SalesTagRecord[];
  can_tag_sales?: boolean;
  can_view_broken_sales?: boolean;
  broken_problem_count?: number | null;
  last_sync_time?: string | null;
  last_sync_at?: string | null;
};

function indexElement({
  sales = [makeSaleIndexRecord()],
  pagination = makePagination(),
  search = { q: "" },
  sort = "newest",
  filters = { hide_partial_payments: false, missing_purchases_only: false, tag_id: null },
  tag_options = [],
  can_tag_sales = true,
  can_view_broken_sales = true,
  broken_problem_count = 0,
  last_sync_time = "20.05 at 10:00",
  last_sync_at = null,
}: IndexOptions = {}) {
  return (
    <Index
      broken_problem_count={broken_problem_count}
      can_tag_sales={can_tag_sales}
      can_view_broken_sales={can_view_broken_sales}
      filters={filters}
      last_sync_at={last_sync_at}
      last_sync_time={last_sync_time}
      pagination={pagination}
      sales={sales}
      search={search}
      sort={sort}
      tag_colors={[...tagColors]}
      tag_options={tag_options}
    />
  );
}

async function openEditor(user: UserEvent) {
  await user.click(screen.getByRole("button", { name: "Edit" }));
  return screen.findByRole("dialog", { name: "Edit tags" });
}

async function openTagFilter(user: UserEvent) {
  await user.click(within(tagFilter()).getByRole("button", { name: "Filter by tag" }));
  return screen.findByRole("dialog", { name: "Filter by tag" });
}

function tagFilter() {
  return screen.getByRole("group", { name: "Tag filter" });
}
