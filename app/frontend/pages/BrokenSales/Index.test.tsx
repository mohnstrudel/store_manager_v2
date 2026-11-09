import { router } from "@inertiajs/react";
import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { makePagination } from "@/test/factories";
import { mockPage, nextFormErrors } from "@/test/mocks/inertia";
import type { PaginationMeta } from "@/types/pagination";

import Index from "./Index";
import type {
  AssignmentIssue,
  AssignmentIssueCounts,
  ImportFailureRow,
  IssueFilter,
  IssueType,
  IssueView,
  OrderScope,
  ProductIssueRow,
  SaleItemAssignmentIssue,
} from "./types";

describe("BrokenSales/Index", () => {
  beforeEach(() => {
    mockPage({
      url: "/broken_sales?issue_type=purchases&reason=missing_variant",
    });
  });

  it("renders URL-backed tabs, counts, filters, and pagination", async () => {
    const user = userEvent.setup();

    renderPage({
      counts: {
        purchases: 28,
        sale_items: 3,
        import_failures: 0,
        purchase_item_links: 2,
        sku_collisions: 5,
        shopify_conflicts: 0,
      },
      pagination: makePagination({
        current_page: 2,
        total_pages: 2,
        total_count: 28,
        limit: 25,
      }),
    });

    expect([
      screen.getByRole("tab", { name: "Purchases 28" }).getAttribute("aria-selected"),
      screen.getByRole("tab", { name: "Orders 3" }).getAttribute("href"),
      screen.getByRole("tab", { name: "Purchase links 2" }).getAttribute("href"),
      screen.getByRole("tab", { name: "SKU collisions 5" }).getAttribute("href"),
      screen.getByRole("link", { name: "Previous" }).getAttribute("href"),
    ]).toEqual([
      "true",
      "/broken_sales?issue_type=sale_items",
      "/broken_sales?issue_type=purchase_item_links",
      "/broken_sales?issue_type=sku_collisions",
      "/broken_sales?issue_type=purchases&reason=missing_variant&page=1",
    ]);

    await user.selectOptions(screen.getByRole("combobox", { name: "Issue filter" }), "");

    expect(router.get).toHaveBeenCalledWith(
      "/broken_sales",
      { issue_type: "purchases", reason: undefined },
      { preserveState: true },
    );
  });

  it("hides tabs with no items, keeping the selected empty tab visible", () => {
    renderPage({
      counts: {
        purchases: 0,
        sale_items: 4,
        import_failures: 0,
        purchase_item_links: 0,
        sku_collisions: 0,
        shopify_conflicts: 0,
      },
      issueType: "purchases",
      issues: [],
    });

    expect([
      screen.getByRole("tab", { name: "Purchases 0" }).getAttribute("aria-selected"),
      screen.getByRole("tab", { name: "Orders 4" }).getAttribute("href"),
      screen.queryByRole("tab", { name: /Purchase links/ }),
      screen.queryByRole("tab", { name: /SKU collisions/ }),
    ]).toEqual(["true", "/broken_sales?issue_type=sale_items", null, null]);
  });

  it("repairs a Purchase with a Rails-owned historical candidate and reloads all issue props", async () => {
    const user = userEvent.setup();
    const issue = makePurchaseIssue();

    renderPage({ issues: [issue] });

    const row = screen.getByRole("row", { name: /BROKEN-42/ });
    expect(within(row).getAllByText("Missing Variant")).not.toHaveLength(0);
    expect(within(row).getByText("1 inventory unit; 1 linked unit")).toBeInTheDocument();

    await user.click(within(row).getByRole("button", { name: "Edit" }));
    await user.selectOptions(
      within(row).getByRole("combobox", { name: "Variant for BROKEN-42" }),
      "12",
    );
    await user.click(within(row).getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/broken_sales/purchases/7",
      {
        purchase: { variant_id: "12" },
        return_to: "/broken_sales?issue_type=purchases&reason=missing_variant",
      },
      expect.objectContaining({
        only: ["issues", "counts", "pagination", "repairable"],
      }),
    );
  });

  it("keeps the selected candidate visible when the backend rejects an inline repair", async () => {
    const user = userEvent.setup();
    nextFormErrors.mockReturnValueOnce({
      variant_id: "Variant is not an available repair candidate",
    });

    renderPage({ issues: [makePurchaseIssue()] });

    const row = screen.getByRole("row", { name: /BROKEN-42/ });
    await user.click(within(row).getByRole("button", { name: "Edit" }));
    await user.selectOptions(
      within(row).getByRole("combobox", { name: "Variant for BROKEN-42" }),
      "12",
    );
    await user.click(within(row).getByRole("button", { name: "Save" }));

    expect(
      within(row).getByText("Variant is not an available repair candidate"),
    ).toBeInTheDocument();
    expect(within(row).getByRole("combobox", { name: "Variant for BROKEN-42" })).toHaveValue("12");
  });

  it("shows link evidence and runs one silent repair resource", async () => {
    const user = userEvent.setup();
    const linkIssue: AssignmentIssue = {
      kind: "purchase_item_link",
      id: 31,
      reason: "sale_item_identity",
      purchase_id: 4,
      purchase_path: "/purchases/purchase-4",
      sale_item_id: 9,
      sale_path: "/sales/2",
      purchase_product_title: "Product A",
      purchase_variant_label: "Blue",
      sale_product_title: "Product B",
      sale_variant_label: "Large",
      exact_replacements_available: 1,
      exact_replacement_ids: [44],
      remaining_capacity_after_unlink: 2,
    };

    renderPage({
      issueType: "purchase_item_links",
      filter: "",
      filters: [
        { value: "purchase_identity", label: "Purchase identity mismatch" },
        { value: "sale_item_identity", label: "SaleItem identity mismatch" },
      ],
      issues: [linkIssue],
    });

    expect(screen.getByText("Product A / Blue")).toBeInTheDocument();
    expect(screen.getByText("Product B / Large")).toBeInTheDocument();
    expect(
      screen.getByText("1 exact replacement available; 2 open slots after unlink"),
    ).toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Repair PurchaseItem link 31" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/broken_sales/purchase_item_links/31",
      {
        return_to: "/broken_sales?issue_type=purchases&reason=missing_variant",
      },
      expect.objectContaining({
        only: ["issues", "counts", "pagination", "repairable"],
        preserveScroll: true,
      }),
    );
  });

  it("renders the sku_collisions tab with count badge and no repair action", () => {
    const skuIssue: AssignmentIssue = {
      kind: "sku_collision",
      id: 21,
      sku: "dup-1",
      product_id: 3,
      product_title: "Product A",
      variant_label: "Active",
      edit_path: "/products/3/edit",
      colliding_with: [
        {
          product_id: 4,
          product_title: "Product B",
          variant_id: 22,
          variant_label: "Base Model",
          edit_path: "/products/4/edit",
        },
      ],
    };

    renderPage({
      counts: {
        purchases: 1,
        sale_items: 0,
        import_failures: 0,
        purchase_item_links: 0,
        sku_collisions: 1,
        shopify_conflicts: 0,
      },
      issueType: "sku_collisions",
      filter: "",
      filters: [],
      issues: [skuIssue],
    });

    const row = screen.getByRole("row", { name: /SKU collision dup-1/ });

    expect([
      screen.getByRole("tab", { name: "SKU collisions 1" }).getAttribute("aria-selected"),
      within(row).getByText("Product A / Active").textContent,
      within(row).getByText("Product B / Base Model").textContent,
      within(row).queryByRole("button"),
      screen.queryByRole("combobox", { name: "Issue filter" }),
      within(row).queryByRole("combobox"),
    ]).toEqual(["true", "Product A / Active", "Product B / Base Model", null, null, null]);
  });

  it("renders the shopify_conflicts tab with Shopify options, the Variant already using them, and no repair action", () => {
    const conflict: AssignmentIssue = {
      kind: "shopify_conflict",
      id: 31,
      sku: "zoldyck-b",
      store_id: "gid://shopify/ProductVariant/42",
      shopify_options: [
        { name: "Edition", value: "B" },
        { name: "Version", value: "A" },
      ],
      product_id: 3,
      product_title: "Killua Zoldyck",
      edit_path: "/products/3/edit",
      conflicting_variant_label: "1:1 | A",
      conflicting_variant_sku: "zoldyck-a",
    };

    renderPage({
      counts: {
        purchases: 0,
        sale_items: 0,
        import_failures: 0,
        purchase_item_links: 0,
        sku_collisions: 0,
        shopify_conflicts: 1,
      },
      issueType: "shopify_conflicts",
      filter: "",
      filters: [],
      issues: [conflict],
    });

    const row = screen.getByRole("row", {
      name: /Shopify conflict .*42 on Killua Zoldyck/,
    });

    expect([
      screen.getByRole("tab", { name: "Shopify conflicts 1" }).getAttribute("aria-selected"),
      within(row).getByRole("link", { name: "Killua Zoldyck" }).getAttribute("href"),
      within(row).getByText("Edition: B / Version: A").textContent,
      within(row).getByText("1:1 | A (zoldyck-a)").textContent,
      within(row).queryByRole("button"),
    ]).toEqual([
      "true",
      "/products/3/edit",
      "Edition: B / Version: A",
      "1:1 | A (zoldyck-a)",
      null,
    ]);
  });

  it("hides Fix obvious cases when nothing has a single possible Variant", () => {
    renderPage({ repairable: false });

    expect(screen.queryByRole("button", { name: "Fix obvious cases" })).not.toBeInTheDocument();
  });

  it("shows Fix obvious cases and explains what it skips before running", async () => {
    const user = userEvent.setup();
    const confirm = vi.spyOn(window, "confirm").mockReturnValue(false);
    renderPage({ repairable: true });

    await user.click(screen.getByRole("button", { name: "Fix obvious cases" }));

    expect(confirm).toHaveBeenCalledWith(
      "Assign the Variant to every line that has only one possible Variant? Lines where several Variants fit are skipped and stay here for you to choose.",
    );
    confirm.mockRestore();
  });

  it("uses the approved empty state", () => {
    renderPage({ issues: [], pagination: makePagination({ total_count: 0 }) });

    expect(screen.getByText("No Variant assignment issues")).toBeInTheDocument();
  });

  it("lists the tabs in the approved order", () => {
    renderPage({
      counts: {
        purchases: 1,
        sale_items: 1,
        import_failures: 1,
        purchase_item_links: 1,
        sku_collisions: 1,
        shopify_conflicts: 1,
      },
    });

    expect(screen.getAllByRole("tab").map((tab) => tab.textContent)).toEqual([
      "Orders1",
      "Import failures1",
      "Purchases1",
      "Purchase links1",
      "SKU collisions1",
      "Shopify conflicts1",
    ]);
  });

  it("renders order rows in backend order with store, status, customer, amount, and product", () => {
    mockPage({
      url: "/broken_sales?issue_type=sale_items&scope=all",
    });

    renderPage({
      issueType: "sale_items",
      scope: "all",
      issues: [
        makeOrderIssue({
          id: 2,
          reference: "Order 4242, item 2",
          order_title: "4242",
        }),
        makeOrderIssue({
          id: 1,
          reference: "Order #1001, item 1",
          order_title: "#1001",
          store_type: "shopify",
          status: "Cancelled",
          customer_name: "Grace Hopper",
          amount: "$30",
        }),
      ],
    });

    const rows = screen.getAllByRole("row").slice(1);

    expect(rows.map((row) => row.getAttribute("aria-label"))).toEqual([
      "Order 4242, item 2",
      "Order #1001, item 1",
    ]);
    expect(
      within(rows[1])
        .getAllByRole("cell")
        .slice(0, 5)
        .map((cell) => cell.textContent),
    ).toEqual(["#1001", "Cancelled", "Grace Hopper", "$30", "Product A"]);
    expect(within(rows[1]).getByRole("link", { name: "Shopify order #1001" })).toHaveAttribute(
      "href",
      "/sales/9",
    );
    expect(within(rows[0]).getByRole("link", { name: "Woo order 4242" })).toBeInTheDocument();
    expect(rows[1].querySelector(".icon_shopify")).toHaveAttribute("aria-hidden", "true");
    expect(within(rows[1]).getByRole("button", { name: "Edit" })).toBeInTheDocument();
  });

  it("names an order without a store by its Sale id", () => {
    renderPage({
      issueType: "sale_items",
      issues: [makeOrderIssue({ order_title: "Sale 9", store_type: null })],
    });

    const row = screen.getByRole("row", { name: "Order 4242, item 5" });
    expect(within(row).getByRole("link", { name: "Sale 9" })).toHaveAttribute("href", "/sales/9");
    expect(row.querySelector(".icon_woo, .icon_shopify")).toBeNull();
  });

  it("shows why an order is not updating and pulls it again", async () => {
    const user = userEvent.setup();
    mockPage({ url: "/broken_sales?issue_type=sale_items" });

    renderPage({
      issueType: "sale_items",
      issues: [
        makeOrderIssue({
          consequences: [
            {
              kind: "not_updating",
              text: "Not updating from Woo since 9. Nov ’26: status and payments here may be out of date.",
            },
          ],
          import_failure: {
            message: "Line 2: Woo product 5 was not found",
            last_failed_at: "9. Nov ’26 14:05",
            pull_path: "/sales/9/pull",
            sentry_url: "https://handsomecake-goodies.sentry.io/issues/?query=abc123",
          },
        }),
      ],
    });

    const row = screen.getByRole("row", { name: "Order 4242, item 5" });
    expect(within(row).getByText("Line 2: Woo product 5 was not found")).toBeInTheDocument();
    expect(
      within(row).getByRole("link", { name: "Open Woo order 4242 in Sentry" }),
    ).toHaveAttribute("href", "https://handsomecake-goodies.sentry.io/issues/?query=abc123");

    await user.click(within(row).getByRole("button", { name: "Pull Woo order 4242 again" }));

    expect(router.post).toHaveBeenCalledWith(
      "/sales/9/pull",
      { return_to: "/broken_sales?issue_type=sale_items" },
      { preserveScroll: true },
    );
  });

  it("lists what the business loses on each order row in backend order", () => {
    renderPage({
      issueType: "sale_items",
      issues: [
        makeOrderIssue({
          consequences: [
            {
              kind: "units_not_reserved",
              text: "2 units for Anna Müller aren't reserved. They may not arrive on time.",
            },
            {
              kind: "debt_miscounted",
              text: "Revealing Armor may be under-ordered: this sale isn't counted in what we owe.",
            },
          ],
        }),
      ],
    });

    const impact = within(screen.getByRole("row", { name: "Order 4242, item 5" })).getByRole(
      "list",
      { name: "Impact" },
    );

    expect(
      within(impact)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual([
      "2 units for Anna Müller aren't reserved. They may not arrive on time.",
      "Revealing Armor may be under-ordered: this sale isn't counted in what we owe.",
    ]);
    expect(screen.getByRole("columnheader", { name: "Impact" })).toBeInTheDocument();
  });

  it("shows the history impact for a closed order", () => {
    renderPage({
      issueType: "sale_items",
      issues: [
        makeOrderIssue({
          status: "Cancelled",
          consequences: [
            {
              kind: "variant_not_recorded",
              text: "History doesn't record which Variant Anna Müller bought.",
            },
          ],
        }),
      ],
    });

    const row = screen.getByRole("row", { name: "Order 4242, item 5" });

    expect(
      within(row)
        .getAllByRole("listitem")
        .map((item) => item.textContent),
    ).toEqual(["History doesn't record which Variant Anna Müller bought."]);
    expect(within(row).getByRole("listitem")).not.toHaveClass("text-gray-500");
  });

  it("shows no import error for an order that imports", () => {
    renderPage({ issueType: "sale_items", issues: [makeOrderIssue()] });

    expect(screen.queryByText(/Not updating/)).not.toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /again/ })).not.toBeInTheDocument();
  });

  it("lists import failures by store order with dates, count, and actions", async () => {
    const user = userEvent.setup();
    mockPage({ url: "/broken_sales?issue_type=import_failures&page=2" });

    renderPage({
      issueType: "import_failures",
      filter: "",
      filters: [],
      issues: [
        makeImportFailure(),
        makeImportFailure({
          id: 2,
          store_type: "shopify",
          order_title: "5150",
          record_path: null,
          message: "Shopify order failed",
          failure_count: 1,
          pull_path: "/broken_sales/import_failures/2/pull",
          sentry_url: null,
        }),
      ],
    });

    const woo = screen.getByRole("row", { name: "Woo order 77" });
    expect(
      within(woo)
        .getAllByRole("cell")
        .slice(0, 5)
        .map((cell) => cell.textContent),
    ).toEqual(["77", "Import failed", "8. Nov ’26 10:00", "9. Nov ’26 14:05", "3"]);
    expect(within(woo).getByRole("link", { name: "Woo order 77" })).toHaveAttribute(
      "href",
      "/sales/12",
    );
    expect(within(woo).getByRole("link", { name: "Open Woo order 77 in Sentry" })).toHaveAttribute(
      "target",
      "_blank",
    );

    const shopify = screen.getByRole("row", { name: "Shopify order 5150" });
    expect(within(shopify).queryByRole("link")).not.toBeInTheDocument();
    expect(within(shopify).getByText("5150")).toBeInTheDocument();

    await user.click(
      within(shopify).getByRole("button", {
        name: "Pull Shopify order 5150 again",
      }),
    );

    expect(router.post).toHaveBeenCalledWith(
      "/broken_sales/import_failures/2/pull",
      { return_to: "/broken_sales?issue_type=import_failures&page=2" },
      { preserveScroll: true },
    );
  });

  it("shows an empty state for the Import failures tab", () => {
    renderPage({
      issueType: "import_failures",
      filter: "",
      filters: [],
      issues: [],
    });

    expect(screen.getByText("No orders are failing to import")).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("repairs an order line and reloads the page data", async () => {
    const user = userEvent.setup();
    mockPage({
      url: "/broken_sales?issue_type=sale_items&scope=active",
    });

    renderPage({
      issueType: "sale_items",
      scope: "active",
      issues: [makeOrderIssue()],
    });

    const row = screen.getByRole("row", { name: "Order 4242, item 5" });
    await user.click(within(row).getByRole("button", { name: "Edit" }));
    await user.selectOptions(
      within(row).getByRole("combobox", {
        name: "Variant for Order 4242, item 5",
      }),
      "11",
    );
    await user.click(within(row).getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/broken_sales/sale_items/5",
      {
        sale_item: { variant_id: "11" },
        return_to: "/broken_sales?issue_type=sale_items&scope=active",
      },
      expect.objectContaining({
        only: ["issues", "counts", "pagination", "repairable"],
      }),
    );
  });

  it("links each order scope through the URL and keeps the Product filter chip", () => {
    renderPage({
      issueType: "sale_items",
      scope: "closed",
      productId: 3,
      productTitle: "Product A",
      filter: "",
      filters: [],
      issues: [makeOrderIssue()],
      pagination: makePagination({
        current_page: 1,
        total_pages: 2,
        total_count: 30,
        limit: 25,
      }),
    });

    const scopes = screen.getByRole("tablist", { name: "Order scope" });

    expect(
      within(scopes)
        .getAllByRole("tab")
        .map((tab) => [
          tab.textContent,
          tab.getAttribute("href"),
          tab.getAttribute("aria-selected"),
        ]),
    ).toEqual([
      ["Active", "/broken_sales?issue_type=sale_items&scope=active&product_id=3", "false"],
      ["All", "/broken_sales?issue_type=sale_items&scope=all&product_id=3", "false"],
      ["Closed", "/broken_sales?issue_type=sale_items&scope=closed&product_id=3", "true"],
    ]);
    expect(screen.getByRole("link", { name: "Next" })).toHaveAttribute(
      "href",
      "/broken_sales?issue_type=sale_items&view=orders&scope=closed&product_id=3&page=2",
    );
    const chip = screen.getByRole("link", {
      name: "Remove Product A from the Product filter",
    });
    expect([chip.textContent, chip.getAttribute("href")]).toEqual([
      "Product: Product A",
      "/broken_sales?issue_type=sale_items&scope=closed",
    ]);
  });

  it("shows no Product chip when orders are not filtered by Product", () => {
    renderPage({
      issueType: "sale_items",
      filter: "",
      filters: [],
      issues: [makeOrderIssue()],
    });

    expect(screen.queryByRole("link", { name: /Product filter/ })).not.toBeInTheDocument();
  });

  it.each<[IssueType, IssueView | null]>([
    ["sale_items", "orders"],
    ["sale_items", "products"],
    ["import_failures", null],
  ])("shows no issue filter or description on %s in the %s view", (issueType, view) => {
    renderPage({ issueType, view, filter: "", filters: [], issues: [] });

    expect([
      screen.queryByRole("combobox", { name: "Issue filter" }),
      screen.queryByTestId("issue-description"),
    ]).toEqual([null, null]);
  });

  it.each<IssueType>(["purchases", "purchase_item_links", "sku_collisions", "shopify_conflicts"])(
    "describes the %s tab in one short sentence",
    (issueType) => {
      renderPage({ issueType, issues: [] });

      const description = screen.getByTestId("issue-description").textContent ?? "";

      expect([description.split(" ").length <= 15, description.match(/[.!?]/g)?.length]).toEqual([
        true,
        1,
      ]);
    },
  );

  it.each<[OrderScope, string]>([
    ["active", "No active orders need a Variant"],
    ["all", "No orders need a Variant"],
    ["closed", "No closed orders need a Variant"],
  ])("shows an empty state for the %s scope", (scope, message) => {
    renderPage({ issueType: "sale_items", scope, issues: [] });

    expect(screen.getByText(message)).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });

  it("groups orders by Product through the toolbar checkbox, clearing the Product filter", async () => {
    const user = userEvent.setup();

    renderPage({
      issueType: "sale_items",
      scope: "closed",
      productId: 3,
      productTitle: "Product A",
      filter: "",
      filters: [],
      issues: [makeOrderIssue()],
    });

    await user.click(screen.getByRole("checkbox", { name: "Group by Product" }));

    expect(router.get).toHaveBeenCalledWith("/broken_sales?issue_type=sale_items&view=products");
  });

  it("shows Product rows without the scope control and returns to order rows when unchecked", async () => {
    const user = userEvent.setup();

    renderPage({
      issueType: "sale_items",
      view: "products",
      scope: null,
      filter: "",
      filters: [],
      issues: [makeProductRow()],
    });

    const groupByProduct = screen.getByRole("checkbox", {
      name: "Group by Product",
    });

    expect([
      (groupByProduct as HTMLInputElement).checked,
      screen.queryByRole("tablist", { name: "Order scope" }),
      screen.queryByRole("tablist", { name: "Order view" }),
      screen.queryByRole("link", { name: /Product filter/ }),
    ]).toEqual([true, null, null, null]);

    await user.click(groupByProduct);

    expect(router.get).toHaveBeenCalledWith("/broken_sales?issue_type=sale_items&view=orders");
  });

  it("lists Products with their numbers and links each to its orders", () => {
    renderPage({
      issueType: "sale_items",
      view: "products",
      issues: [makeProductRow()],
    });

    const row = screen.getByRole("row", { name: "Product A" });

    expect(
      within(row)
        .getAllByRole("cell")
        .slice(0, 4)
        .map((cell) => cell.textContent),
    ).toEqual(["Product A", "4 orders", "1", "$135"]);
    expect(within(row).getByRole("link", { name: "4 orders" })).toHaveAttribute(
      "href",
      "/broken_sales?issue_type=sale_items&view=orders&product_id=3",
    );
  });

  it("confirms with the Product, Variant, and line count before assigning closed orders", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    mockPage({
      url: "/broken_sales?issue_type=sale_items&view=products",
    });
    renderPage({
      issueType: "sale_items",
      view: "products",
      issues: [makeProductRow()],
    });

    const row = screen.getByRole("row", { name: "Product A" });
    await user.selectOptions(
      within(row).getByRole("combobox", {
        name: "Variant for closed orders of Product A",
      }),
      "11",
    );
    await user.click(within(row).getByRole("button", { name: "Assign to closed orders" }));

    expect(window.confirm).toHaveBeenCalledWith(
      "Assign Red to 2 closed order lines of Product A? Lines with linked purchases are skipped.",
    );
    expect(router.post).toHaveBeenCalledWith(
      "/broken_sales/products/3/closed_order_repair",
      {
        closed_order_repair: { variant_id: "11" },
        return_to: "/broken_sales?issue_type=sale_items&view=products",
      },
      expect.objectContaining({
        only: ["issues", "counts", "pagination", "repairable"],
        preserveScroll: true,
      }),
    );
  });

  it("does not assign closed orders when the confirmation is dismissed", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(false);
    renderPage({
      issueType: "sale_items",
      view: "products",
      issues: [makeProductRow()],
    });

    const row = screen.getByRole("row", { name: "Product A" });
    await user.selectOptions(within(row).getByRole("combobox"), "11");
    await user.click(within(row).getByRole("button", { name: "Assign to closed orders" }));

    expect(router.post).not.toHaveBeenCalled();
  });

  it("shows the rejected Variant error inline on the Product row", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    nextFormErrors.mockReturnValue({
      variant_id: "Variant is not an available repair candidate",
    });
    renderPage({
      issueType: "sale_items",
      view: "products",
      issues: [makeProductRow()],
    });

    const row = screen.getByRole("row", { name: "Product A" });
    await user.selectOptions(within(row).getByRole("combobox"), "11");
    await user.click(within(row).getByRole("button", { name: "Assign to closed orders" }));

    expect(
      within(row).getByText("Variant is not an available repair candidate"),
    ).toBeInTheDocument();
  });

  it("offers no bulk assignment for a Product without closed orders", () => {
    renderPage({
      issueType: "sale_items",
      view: "products",
      issues: [makeProductRow({ closed_line_count: 0 })],
    });

    const row = screen.getByRole("row", { name: "Product A" });

    expect(within(row).getByText("No closed orders")).toBeInTheDocument();
    expect(within(row).queryByRole("button")).not.toBeInTheDocument();
  });

  it("shows an empty state for the products view", () => {
    renderPage({ issueType: "sale_items", view: "products", issues: [] });

    expect(screen.getByText("No Products have orders that need a Variant")).toBeInTheDocument();
    expect(screen.queryByRole("table")).not.toBeInTheDocument();
  });
});

function renderPage({
  counts = {
    purchases: 1,
    sale_items: 0,
    import_failures: 0,
    purchase_item_links: 0,
    sku_collisions: 0,
    shopify_conflicts: 0,
  },
  filter = "missing_variant",
  filters = [
    { value: "missing_product", label: "Missing Product" },
    { value: "missing_variant", label: "Missing Variant" },
    { value: "product_mismatch", label: "Product / Variant mismatch" },
  ],
  issueType = "purchases",
  issues = [makePurchaseIssue()],
  pagination = makePagination({ total_count: issues.length }),
  productId = null,
  productTitle = null,
  repairable = true,
  scope = issueType === "sale_items" ? "all" : null,
  view = issueType === "sale_items" ? "orders" : null,
}: {
  counts?: AssignmentIssueCounts;
  filter?: string;
  filters?: IssueFilter[];
  issueType?: IssueType;
  issues?: AssignmentIssue[];
  pagination?: PaginationMeta;
  productId?: number | null;
  productTitle?: string | null;
  repairable?: boolean;
  scope?: OrderScope | null;
  view?: IssueView | null;
} = {}) {
  return render(
    <Index
      counts={counts}
      filter={filter}
      filters={filters}
      issue_type={issueType}
      issues={issues}
      pagination={pagination}
      product_id={productId}
      product_title={productTitle}
      repairable={repairable}
      scope={scope}
      view={view}
    />,
  );
}

function makePurchaseIssue(): AssignmentIssue {
  return {
    kind: "purchase",
    id: 7,
    reason: "missing_variant",
    reference: "BROKEN-42",
    product_id: 3,
    product_title: "Product A",
    variant_id: null,
    current_variant_label: "Missing Variant",
    current_variant_product_id: null,
    candidates: [
      { value: 11, label: "Active", base_model: false },
      { value: 12, label: "Archive (Historical)", base_model: false },
    ],
    inventory_units: 1,
    linked_units: 1,
    record_path: "/purchases/purchase-7",
  };
}

function makeOrderIssue(overrides: Partial<SaleItemAssignmentIssue> = {}): SaleItemAssignmentIssue {
  return {
    kind: "sale_item",
    id: 5,
    reason: "missing_variant",
    reference: "Order 4242, item 5",
    order_title: "4242",
    store_type: "woo",
    status: "Processing",
    customer_name: "Ada Lovelace",
    amount: "$100",
    product_id: 3,
    product_title: "Product A",
    variant_id: null,
    current_variant_label: "Missing Variant",
    current_variant_product_id: null,
    candidates: [{ value: 11, label: "Active", base_model: false }],
    record_path: "/sales/9",
    import_failure: null,
    consequences: [],
    ...overrides,
  };
}

function makeImportFailure(overrides: Partial<ImportFailureRow> = {}): ImportFailureRow {
  return {
    kind: "import_failure",
    id: 1,
    store_type: "woo",
    order_title: "77",
    record_path: "/sales/12",
    message: "Import failed",
    first_failed_at: "8. Nov ’26 10:00",
    last_failed_at: "9. Nov ’26 14:05",
    failure_count: 3,
    pull_path: "/sales/12/pull",
    sentry_url: "https://handsomecake-goodies.sentry.io/issues/?query=abc123",
    ...overrides,
  };
}

function makeProductRow(overrides: Partial<ProductIssueRow> = {}): ProductIssueRow {
  return {
    kind: "product",
    id: 3,
    product_title: "Product A",
    order_count: 4,
    active_order_count: 1,
    closed_line_count: 2,
    revenue: "$135",
    candidates: [
      { value: 11, label: "Red", base_model: false },
      { value: 12, label: "Blue", base_model: false },
    ],
    ...overrides,
  };
}
