import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";
import type { DashboardIndex, DashboardSaleDebt, DashboardSupplierDebt } from "@/types/serializers";

import Index from "./Index";

type SaleDebtRecord = DashboardSaleDebt;

type SupplierDebtRecord = DashboardSupplierDebt;

function makeSaleDebt(overrides: Partial<SaleDebtRecord> = {}): SaleDebtRecord {
  return {
    id: 1,
    row_id: 1,
    path: "/sales/1",
    title: "Moon Statue",
    variant_name: "Gold",
    debt: 3,
    ...overrides,
  };
}

function makeSupplierDebt(overrides: Partial<SupplierDebtRecord> = {}): SupplierDebtRecord {
  return {
    supplier_id: 10,
    supplier_title: "Acme Imports",
    supplier_path: "/suppliers/10",
    total_cost: "500.00",
    total_size: 4,
    paid: "200.00",
    total_debt: "300.00",
    ...overrides,
  };
}

const defaultProps: Required<DashboardIndex> = {
  debts_path: "/debts",
  last_orders_pull_path: "/orders/pull",
  sale_debts: { rows: [makeSaleDebt()], count: 1 },
  sales_hook_disabled: false,
  supplier_debts: { rows: [], total: "0.00" },
};

function renderIndex(overrides: Partial<typeof defaultProps> = {}) {
  const props = { ...defaultProps, ...overrides };
  mockPageProps(props);
  return render(<Index {...props} />);
}

describe("Dashboard/Index", () => {
  it("renders the Dashboard heading and sale debt rows", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Dashboard" })).toBeInTheDocument();
    expect(screen.getByText("Moon Statue")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "See More..." })).toHaveAttribute("href", "/debts");
  });

  it("shows loading sections until the debt reports arrive", () => {
    mockPageProps({ debts_path: "/debts", sales_hook_disabled: false });
    render(
      <Index
        debts_path="/debts"
        last_orders_pull_path="/orders/pull"
        sales_hook_disabled={false}
      />,
    );

    expect(screen.getByRole("region", { name: "Products Short" })).toHaveAttribute(
      "aria-busy",
      "true",
    );
    expect(screen.getByRole("region", { name: "Supplier Debt" })).toHaveAttribute(
      "aria-busy",
      "true",
    );
    expect(screen.queryByText("Moon Statue")).not.toBeInTheDocument();
  });

  it("shows the suppliers debt section when supplier debts are present", () => {
    renderIndex({ supplier_debts: { rows: [makeSupplierDebt()], total: "300.00" } });

    expect(screen.getByText("Acme Imports")).toBeInTheDocument();
    expect(screen.getAllByText("300.00")).toHaveLength(2);
  });

  it("hides the suppliers debt section when there are no supplier debts", () => {
    renderIndex();

    expect(screen.queryByText("Supplier Debt")).not.toBeInTheDocument();
  });

  it("shows the webhook warning when sales_hook_disabled is true", () => {
    renderIndex({ sales_hook_disabled: true });

    expect(screen.getByText("The WooCommerce Sales Webhook is Deactivated")).toBeInTheDocument();
  });

  it("hides the webhook warning when sales_hook_disabled is false", () => {
    renderIndex();

    expect(
      screen.queryByText("The WooCommerce Sales Webhook is Deactivated"),
    ).not.toBeInTheDocument();
  });
});
