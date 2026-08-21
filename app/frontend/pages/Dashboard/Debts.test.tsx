import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makePagination } from "@/test/factories";

import Debts from "./Debts";

type DebtRecord = {
  id: number;
  path: string;
  row_id: number;
  title: string;
  variant_name: string;
  sold_amount: number;
  purchased_amount: number;
  debt: number;
};

type UnpaidPurchaseRecord = {
  id: number;
  path: string;
  purchased_ago: string;
  supplier_title: string;
  item_price: string;
  amount: number;
};

function makeDebt(overrides: Partial<DebtRecord> = {}): DebtRecord {
  return {
    id: 1,
    row_id: 1,
    path: "/sales/1",
    title: "Moon Statue",
    variant_name: "Gold",
    sold_amount: 5,
    purchased_amount: 2,
    debt: 3,
    ...overrides,
  };
}

function makeUnpaidPurchase(overrides: Partial<UnpaidPurchaseRecord> = {}): UnpaidPurchaseRecord {
  return {
    id: 10,
    path: "/purchases/10",
    purchased_ago: "3 months ago",
    supplier_title: "Acme Imports",
    item_price: "120.00",
    amount: 2,
    ...overrides,
  };
}

const defaultProps = {
  debts: [makeDebt()],
  pagination: makePagination(),
  search: { q: "" },
  unpaid_purchases: [],
};

describe("Dashboard/Debts", () => {
  it("renders the Debts heading and debt table rows", () => {
    render(<Debts {...defaultProps} />);

    expect(screen.getByRole("heading", { name: "Debts" })).toBeInTheDocument();
    expect(screen.getByText("Moon Statue")).toBeInTheDocument();
    expect(screen.getByText("Gold")).toBeInTheDocument();
  });

  it("shows the unpaid purchases section when unpaid_purchases is non-empty", () => {
    render(<Debts {...defaultProps} unpaid_purchases={[makeUnpaidPurchase()]} />);

    expect(screen.getByText("Purchases Without Payments")).toBeInTheDocument();
    expect(screen.getByText("Acme Imports")).toBeInTheDocument();
    expect(screen.getByText("3 months ago")).toBeInTheDocument();
  });

  it("hides the unpaid purchases section when unpaid_purchases is empty", () => {
    render(<Debts {...defaultProps} unpaid_purchases={[]} />);

    expect(screen.queryByText("Purchases Without Payments")).not.toBeInTheDocument();
  });
});
