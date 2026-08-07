import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import ProductEconomicsDashboard from "./ProductEconomicsDashboard";
import { makeProfitability } from "../test/factories";
import { type ProfitabilityRecord } from "../types";

function renderDashboard(overrides: Partial<ProfitabilityRecord> = {}) {
  return render(<ProductEconomicsDashboard profitability={makeProfitability(overrides)} />);
}

const withoutCosts = { business_expenses: null, purchase_cost: null };

describe("Products/Show/ProductEconomicsDashboard", () => {
  it("states the whole profit picture in one row", () => {
    renderDashboard();

    const summary = within(screen.getByTestId("profitability-snapshot-card"));

    expect(summary.getByText("Revenue")).toBeInTheDocument();
    expect(summary.getByText("Merchandise")).toBeInTheDocument();
    expect(summary.getByText("Direct")).toBeInTheDocument();
    expect(summary.getByText("OpEx")).toBeInTheDocument();
    expect(summary.getByText("Net Profit")).toBeInTheDocument();
    expect(summary.getByText("In hand")).toBeInTheDocument();
    expect(rows("profitability-snapshot-card")).toHaveLength(1);
  });

  it("leaves no operator between the terms", () => {
    renderDashboard({ expected_final_profit: "-953" });

    expect(operatorGlyphs("profitability-snapshot-card")).toEqual([]);
    // The minus on a negative amount is part of the figure, not an operator.
    expect(
      within(screen.getByTestId("profitability-snapshot-card")).getByText("−953"),
    ).toBeInTheDocument();
  });

  it("names the OpEx term without repeating the rate it came from", () => {
    renderDashboard({ expense_rate_percent: 35, business_expenses: "2 255" });

    const summaryCard = screen.getByTestId("profitability-snapshot-card");

    expect(within(summaryCard).getByText("OpEx")).toBeInTheDocument();
    expect(summaryCard).not.toHaveTextContent("35%");
  });

  it("renders the profit values", () => {
    renderDashboard({
      expected_final_profit: "953",
      expected_revenue: "5 783",
      merchandise_cost: "2 275",
      direct_expenses: "205",
      business_expenses: "2 255",
    });

    expect(amount("revenue")).toBe(5783);
    expect(amount("merchandise")).toBe(2275);
    expect(amount("directExpenses")).toBe(205);
    expect(amount("opEx")).toBe(2255);
    expect(amount("netProfit")).toBe(953);
  });

  describe("a figure that is zero or absent", () => {
    // `format_money` returns nothing for zero as well as for absent, so a
    // product whose direct expenses equal its purchase cost has a merchandise
    // cost of zero — which used to render a heading over empty space.
    it("takes its label with it rather than heading an empty space", () => {
      renderDashboard({ merchandise_cost: null, direct_expenses: null });

      expect(term("merchandise")).toBeNull();
      expect(term("directExpenses")).toBeNull();
      expect(screen.queryByText("Merchandise")).not.toBeInTheDocument();
      expect(screen.queryByText("Direct")).not.toBeInTheDocument();
      expect(amount("revenue")).toBeGreaterThan(0);
    });

    it("drops the OpEx term when no rates are configured", () => {
      renderDashboard({ expense_rate_percent: 0, business_expenses: null });

      expect(term("opEx")).toBeNull();
      expect(screen.queryByText(/OpEx/)).not.toBeInTheDocument();
    });

    it("drops the profit-in-hand figure when nothing has been received", () => {
      renderDashboard({ realized_profit: null });

      expect(term("profitInHand")).toBeNull();
      expect(screen.queryByText("In hand")).not.toBeInTheDocument();
    });

    it("drops the whole cash group when no cash figure is known", () => {
      renderDashboard({
        received_revenue: null,
        outstanding_revenue: null,
        refunded_revenue: null,
      });

      expect(term("received")).toBeNull();
      expect(term("outstanding")).toBeNull();
      expect(term("refunded")).toBeNull();
      expect(rows("profitability-snapshot-card")).toHaveLength(1);
    });
  });

  it("renders a negative net profit with matching label and value tones", () => {
    renderDashboard({ expected_final_profit: "-953" });

    const summaryCard = screen.getByTestId("profitability-snapshot-card");

    expect(within(summaryCard).getByText("Net Profit").parentElement).toHaveAttribute(
      "data-tone",
      "negative",
    );
    expect(within(summaryCard).getByText("−953")).toHaveAttribute("data-tone", "negative");
  });

  it("states the profit on money received beside the profit on the full sale value", () => {
    renderDashboard({ expected_final_profit: "600", realized_profit: "220" });

    expect(amount("netProfit")).toBe(600);
    expect(amount("profitInHand")).toBe(220);
    expect(group("netProfit")).toBe(group("profitInHand"));
  });

  it("states cash collected, owed and paid back as figures of their own", () => {
    renderDashboard({
      received_revenue: "700",
      outstanding_revenue: "300",
      refunded_revenue: "50",
    });

    expect(amount("received")).toBe(700);
    expect(amount("outstanding")).toBe(300);
    expect(amount("refunded")).toBe(50);
    expect(group("received")).toBe(group("outstanding"));
    expect(group("received")).not.toBe(group("netProfit"));
  });

  it("no longer reports cash or margin as small print", () => {
    renderDashboard({
      margin_percent: 81.79,
      received_revenue: "4 872",
      refunded_revenue: "50",
    });

    const summaryCard = screen.getByTestId("profitability-snapshot-card");

    expect(summaryCard).not.toHaveTextContent("81.79% margin");
    expect(summaryCard).not.toHaveTextContent("50 refunded");
    expect(summaryCard).not.toHaveTextContent("4 872 received");
  });

  // Every figure here is a sum over the product's sales. Without the count a
  // reader cannot tell a total from a per-sale average.
  describe("the scope note", () => {
    it("names how many sales each figure was added up from", async () => {
      renderDashboard({ counted_sales_total: 12 });

      await openHint("revenue");

      expect(screen.getByText(/Across all 12 sales of this product\./)).toBeInTheDocument();
    });

    // One sale is how a reader takes these figures anyway, so a note there
    // would spend a line saying nothing.
    it("stays silent when the product has sold once", async () => {
      renderDashboard({ counted_sales_total: 1 });

      await openHint("netProfit");

      expect(
        screen.getByText(/Revenue minus the cost of goods sold and estimated OpEx\./),
      ).toBeInTheDocument();
      expect(screen.queryByText(/Across/)).not.toBeInTheDocument();
    });

    it.each(["merchandise", "opEx", "profitInHand", "received"])(
      "closes the %s hint with the same count",
      async (anchor) => {
        renderDashboard({ counted_sales_total: 12, received_revenue: "700" });

        await openHint(anchor);

        expect(screen.getByText(/Across all 12 sales/)).toBeInTheDocument();
      },
    );

    // Invested counts purchased units, not sales — claiming a sale count
    // there would attribute the figure to the wrong thing entirely.
    it("keeps the sale count off the invested figure", async () => {
      renderDashboard({ counted_sales_total: 12, invested_total: "420" });

      await openHint("invested");

      expect(screen.queryByText(/Across all 12 sales/)).not.toBeInTheDocument();
    });
  });

  describe("the invested card", () => {
    it("states the total invested beside the cost tied up in unsold stock", () => {
      renderDashboard({ invested_total: "420", remaining_inventory_cost: "240" });

      expect(amount("invested")).toBe(420);
      expect(amount("unsoldStockValue")).toBe(240);
      expect(rows("invested-total-card")).toHaveLength(1);
    });

    it("keeps the warehouse caveat on the figure it qualifies", async () => {
      renderDashboard({ invested_total: "420" });

      const investedCard = screen.getByTestId("invested-total-card");
      expect(investedCard).not.toHaveTextContent("Purchases not received");

      await openHint("invested");

      expect(
        screen.getByText(/Purchases not received into a warehouse are not counted/),
      ).toBeInTheDocument();
    });

    it("drops the unsold stock value when nothing remains unsold", () => {
      renderDashboard({ remaining_inventory_cost: null });

      expect(term("unsoldStockValue")).toBeNull();
      expect(screen.queryByText("Unsold")).not.toBeInTheDocument();
    });

    it("no longer counts units in small print", () => {
      renderDashboard({
        purchased_units_total: 3,
        sold_units_total: 1,
        remaining_units_total: 2,
      });

      expect(screen.getByTestId("invested-total-card")).not.toHaveTextContent(
        "3 purchased, 1 sold, 2 remaining",
      );
    });
  });

  it("keeps the invested total when no costs are recorded, without the profit row", () => {
    renderDashboard(withoutCosts);

    expect(screen.getByTestId("invested-total-card")).toBeInTheDocument();
    expect(screen.queryByTestId("profitability-snapshot-card")).not.toBeInTheDocument();
  });

  it("hides the profit row for a product without sale items, decided by the backend", () => {
    renderDashboard({ has_sale_items: false });

    expect(screen.getByTestId("invested-total-card")).toBeInTheDocument();
    expect(screen.queryByTestId("profitability-snapshot-card")).not.toBeInTheDocument();
  });

  it("renders nothing when no costs are recorded and nothing is invested", () => {
    const { container } = renderDashboard({ ...withoutCosts, invested_total: null });

    expect(container).toBeEmptyDOMElement();
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

  await user.hover(within(termOrFail(anchor)).getByLabelText("More information"));
  await act(async () => {});
}
