import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";

type SaleDebtRecord = {
  id: number;
  path: string;
  row_id: number;
  title: string;
  variant_name: string;
  debt: number;
};

type SupplierDebtRecord = {
  supplier_id: number;
  supplier_title: string;
  supplier_path: string;
  total_cost: string;
  total_size: number;
  paid: string;
  total_debt: string;
};

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

const defaultProps = {
  debts_path: "/debts",
  last_orders_pull_path: "/orders/pull",
  sale_debts: [makeSaleDebt()],
  sale_debts_count: 1,
  sales_hook_disabled: false,
  suppliers_debts: [],
  total_suppliers_debt: "0.00",
};

describe("Dashboard/Index", () => {
  it("renders the Dashboard heading and sale debt rows", () => {
    render(<Index {...defaultProps} />);

    expect(screen.getByRole("heading", { name: "Dashboard" })).toBeInTheDocument();
    expect(screen.getByText("Moon Statue")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "See More..." })).toHaveAttribute("href", "/debts");
  });

  it("shows the suppliers debt section when suppliers_debts is non-empty", () => {
    render(<Index {...defaultProps} suppliers_debts={[makeSupplierDebt()]} />);

    expect(screen.getByText("Acme Imports")).toBeInTheDocument();
    expect(screen.getByText("300.00")).toBeInTheDocument();
  });

  it("hides the suppliers debt section when suppliers_debts is empty", () => {
    render(<Index {...defaultProps} suppliers_debts={[]} />);

    expect(screen.queryByText("Supplier Debt")).not.toBeInTheDocument();
  });

  it("shows the webhook warning when sales_hook_disabled is true", () => {
    render(<Index {...defaultProps} sales_hook_disabled />);

    expect(screen.getByText("The WooCommerce Sales Webhook is Deactivated")).toBeInTheDocument();
  });

  it("hides the webhook warning when sales_hook_disabled is false", () => {
    render(<Index {...defaultProps} sales_hook_disabled={false} />);

    expect(
      screen.queryByText("The WooCommerce Sales Webhook is Deactivated"),
    ).not.toBeInTheDocument();
  });
});
