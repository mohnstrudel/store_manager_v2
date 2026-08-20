import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makeProfitability } from "../test/factories";
import { type ProfitabilityRecord } from "../types";
import ProductEconomicsDashboard from "./ProductEconomicsDashboard";

function renderDashboard(overrides: Partial<ProfitabilityRecord> = {}) {
  return render(<ProductEconomicsDashboard profitability={makeProfitability(overrides)} />);
}

describe("Products/Show/ProductEconomicsDashboard", () => {
  it("states the whole picture in one row", () => {
    renderDashboard();

    const summary = within(screen.getByTestId("profitability-snapshot-card"));

    expect(summary.getByText("Potential Sales")).toBeInTheDocument();
    expect(summary.getByText("Exp. Total Cost")).toBeInTheDocument();
    expect(summary.getByText("Exp. Net Profit")).toBeInTheDocument();
    expect(summary.getByText("Cash today")).toBeInTheDocument();
    expect(rows("profitability-snapshot-card")).toHaveLength(1);
  });

  it("leaves no operator between the terms", () => {
    renderDashboard({ expected_net_profit: "-953" });

    expect(operatorGlyphs("profitability-snapshot-card")).toEqual([]);
    expect(
      within(screen.getByTestId("profitability-snapshot-card")).getByText("−953"),
    ).toBeInTheDocument();
  });

  it("renders the profit values", () => {
    renderDashboard({
      potential_sales: "1 000",
      expected_total_cost: "400",
      expected_net_profit: "500",
    });

    expect(amount("potentialSales")).toBe(1000);
    expect(amount("expectedTotalCost")).toBe(400);
    expect(amount("expectedNetProfit")).toBe(500);
  });

  it("takes its label with it rather than heading an empty space", () => {
    renderDashboard({ expected_total_cost: null });

    expect(term("expectedTotalCost")).toBeNull();
    expect(screen.queryByText("Exp. Total Cost")).not.toBeInTheDocument();
    expect(amount("potentialSales")).toBeGreaterThan(0);
  });

  it("drops the cash position figure when nothing is known", () => {
    renderDashboard({ cash_position: null });

    expect(term("cashPositionToday")).toBeNull();
    expect(screen.queryByText("Cash today")).not.toBeInTheDocument();
  });

  it("renders a negative net profit with matching label and value tones", () => {
    renderDashboard({ expected_net_profit: "-953" });

    const summaryCard = screen.getByTestId("profitability-snapshot-card");

    expect(within(summaryCard).getByText("Exp. Net Profit").parentElement).toHaveAttribute(
      "data-tone",
      "negative",
    );
    expect(within(summaryCard).getByText("−953")).toHaveAttribute("data-tone", "negative");
  });

  it("groups expected net profit beside cash position", () => {
    renderDashboard({ expected_net_profit: "600", cash_position: "220" });

    expect(amount("expectedNetProfit")).toBe(600);
    expect(amount("cashPositionToday")).toBe(220);
    expect(group("expectedNetProfit")).toBe(group("cashPositionToday"));
  });

  it("groups potential sales beside expected total cost", () => {
    renderDashboard({ potential_sales: "1 000", expected_total_cost: "400" });

    expect(group("potentialSales")).toBe(group("expectedTotalCost"));
    expect(group("potentialSales")).not.toBe(group("expectedNetProfit"));
  });

  it("names customer paid and purchase paid separately on the cash position hint", async () => {
    renderDashboard({ received_revenue: "700", purchase_paid: "620", cash_position: "80" });

    await openHint("cashPositionToday");

    expect(screen.getByText(/Customer paid: 700\./)).toBeInTheDocument();
    expect(screen.getByText(/Purchase paid: 620\./)).toBeInTheDocument();
  });

  it("keeps the warehouse caveat on the expected total cost figure", async () => {
    renderDashboard({ expected_total_cost: "420" });

    const summaryCard = screen.getByTestId("profitability-snapshot-card");
    expect(summaryCard).not.toHaveTextContent("Purchases not received");

    await openHint("expectedTotalCost");

    expect(
      screen.getByText(/Purchases not received into a warehouse are not counted/),
    ).toBeInTheDocument();
  });

  it("renders nothing when there is nothing purchased and no cash position", () => {
    const { container } = renderDashboard({ expected_total_cost: null, cash_position: null });

    expect(container).toBeEmptyDOMElement();
  });

  it("makes each label the hover target with no asterisk mark", async () => {
    renderDashboard();
    const summaryCard = screen.getByTestId("profitability-snapshot-card");

    expect(summaryCard.querySelector(".tip_mark__trigger")).toBeNull();
    expect(within(summaryCard).queryByLabelText("More information")).not.toBeInTheDocument();

    const user = userEvent.setup();
    await user.hover(within(summaryCard).getByText("Potential Sales"));
    await act(async () => {});

    expect(
      screen.getByText(/What every purchased unit will earn at its variant's selling price/),
    ).toBeInTheDocument();
  });

  it("names potential sales, expected total cost, and estimated OpEx on the expected net profit hint", async () => {
    renderDashboard({
      potential_sales: "900",
      expected_total_cost: "300",
      business_expenses: "150",
      expected_net_profit: "450",
    });

    await openHint("expectedNetProfit");

    expect(screen.getByText(/Potential sales: 900\./)).toBeInTheDocument();
    expect(screen.getByText(/Expected total cost: 300\./)).toBeInTheDocument();
    expect(screen.getByText(/Estimated OpEx: 150\./)).toBeInTheDocument();
  });
});

function term(anchor: string): HTMLElement | null {
  return screen.queryByTestId(`metric-${anchor}`);
}

function termOrFail(anchor: string): HTMLElement {
  return screen.getByTestId(`metric-${anchor}`);
}

function group(anchor: string): Element | null {
  return termOrFail(anchor).closest(".economics_snapshot__group");
}

function rows(cardTestId: string): NodeListOf<Element> {
  return screen.getByTestId(cardTestId).querySelectorAll(".economics_snapshot__equation");
}

// An operator was an element holding nothing but a glyph. A negative amount
// reads "−953", so matching the whole content tells the two apart.
function operatorGlyphs(cardTestId: string): string[] {
  return [...screen.getByTestId(cardTestId).querySelectorAll("*")]
    .map((element) => element.textContent ?? "")
    .filter((text) => /^[−=→]$/.test(text));
}

function amount(anchor: string): number {
  const text = termOrFail(anchor).querySelector(".economics_snapshot__value")?.textContent ?? "";

  return Number(text.replace(/−/g, "-").replace(/[^\d.-]/g, ""));
}

async function openHint(anchor: string) {
  const user = userEvent.setup();
  const trigger = termOrFail(anchor).querySelector(".metric_label");

  if (trigger === null) throw new Error(`No hover trigger within metric ${anchor}`);

  await user.hover(trigger);
  await act(async () => {});
}
