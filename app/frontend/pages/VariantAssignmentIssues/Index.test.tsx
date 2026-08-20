import { router } from "@inertiajs/react";
import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it } from "vitest";

import { makePagination } from "@/test/factories";
import { mockPage, nextFormErrors } from "@/test/mocks/inertia";

import Index from "./Index";
import type { AssignmentIssue, AssignmentIssueCounts, IssueFilter } from "./types";

describe("VariantAssignmentIssues/Index", () => {
  beforeEach(() => {
    mockPage({
      url: "/variant_assignment_issues?issue_type=purchases&reason=missing_variant",
    });
  });

  it("renders URL-backed tabs, counts, filters, and pagination", async () => {
    const user = userEvent.setup();

    renderPage({
      counts: { purchases: 28, sale_items: 3, purchase_item_links: 2 },
      pagination: makePagination({
        current_page: 2,
        total_pages: 2,
        total_count: 28,
        limit: 25,
      }),
    });

    expect([
      screen.getByRole("link", { name: "Purchases 28" }).getAttribute("aria-current"),
      screen.getByRole("link", { name: "SaleItems 3" }).getAttribute("href"),
      screen.getByRole("link", { name: "PurchaseItem links 2" }).getAttribute("href"),
      screen.getByRole("link", { name: "Previous" }).getAttribute("href"),
    ]).toEqual([
      "page",
      "/variant_assignment_issues?issue_type=sale_items",
      "/variant_assignment_issues?issue_type=purchase_item_links",
      "/variant_assignment_issues?issue_type=purchases&reason=missing_variant&page=1",
    ]);

    await user.selectOptions(screen.getByRole("combobox", { name: "Issue filter" }), "");

    expect(router.get).toHaveBeenCalledWith(
      "/variant_assignment_issues",
      { issue_type: "purchases", reason: undefined },
      { preserveState: true },
    );
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
      "/variant_assignment_issues/purchases/7",
      {
        purchase: { variant_id: "12" },
        return_to: "/variant_assignment_issues?issue_type=purchases&reason=missing_variant",
      },
      expect.objectContaining({
        only: ["issues", "counts", "pagination"],
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
      "/variant_assignment_issues/purchase_item_links/31",
      {
        return_to: "/variant_assignment_issues?issue_type=purchases&reason=missing_variant",
      },
      expect.objectContaining({
        only: ["issues", "counts", "pagination"],
        preserveScroll: true,
      }),
    );
  });

  it("uses the approved empty state", () => {
    renderPage({ issues: [], pagination: makePagination({ total_count: 0 }) });

    expect(screen.getByText("No Variant assignment issues")).toBeInTheDocument();
  });
});

function renderPage({
  counts = { purchases: 1, sale_items: 0, purchase_item_links: 0 },
  filter = "missing_variant",
  filters = [
    { value: "missing_product", label: "Missing Product" },
    { value: "missing_variant", label: "Missing Variant" },
    { value: "product_mismatch", label: "Product / Variant mismatch" },
  ],
  issueType = "purchases",
  issues = [makePurchaseIssue()],
  pagination = makePagination({ total_count: issues.length }),
}: {
  counts?: AssignmentIssueCounts;
  filter?: string;
  filters?: IssueFilter[];
  issueType?: "purchases" | "sale_items" | "purchase_item_links";
  issues?: AssignmentIssue[];
  pagination?: ReturnType<typeof makePagination>;
} = {}) {
  return render(
    <Index
      counts={counts}
      filter={filter}
      filters={filters}
      issue_type={issueType}
      issues={issues}
      pagination={pagination}
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
