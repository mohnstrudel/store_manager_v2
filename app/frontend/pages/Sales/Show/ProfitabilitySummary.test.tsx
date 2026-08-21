import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makeSaleProfitability } from "../test/factories";
import type { SaleProfitabilityRecord } from "../types";
import ProfitabilitySummary from "./ProfitabilitySummary";

const TERM_ANCHORS = [
  "grossRevenue",
  "purchaseCost",
  "netProfit",
  "purchaseExpenses",
  "cashPositionToday",
];

describe("Sales/Show/ProfitabilitySummary", () => {
  it("states five terms, each with its own label and figure", () => {
    renderSummary();

    const labels = [...card().querySelectorAll(".economics_snapshot__label")].map(
      (element) => element.textContent,
    );

    expect(labels).toEqual([
      "Gross Revenue",
      "Pur. Cost",
      "Net Profit",
      "Pur. Expenses",
      "Cash today",
    ]);
    expect(amount("grossRevenue")).toBe(300);
    expect(amount("purchaseCost")).toBe(100);
    expect(amount("netProfit")).toBe(150);
    expect(amount("purchaseExpenses")).toBe(20);
    expect(amount("cashPositionToday")).toBe(40);
  });

  it("keeps every term in a group of its own, so a divider separates each figure", () => {
    renderSummary();

    expect(card().querySelectorAll(".economics_snapshot__group")).toHaveLength(TERM_ANCHORS.length);

    for (const anchor of TERM_ANCHORS) {
      const holder = termOrFail(anchor).closest(".economics_snapshot__group");

      expect(holder?.querySelectorAll(".economics_snapshot__term")).toHaveLength(1);
    }
  });

  it("states its terms without an operator or arrow between them", () => {
    renderSummary({ net_profit: "-96" });

    expect(operatorGlyphs()).toEqual([]);
    // The minus on a negative amount is part of the figure, not an operator.
    expect(within(card()).getByText("−96")).toBeInTheDocument();
  });

  it("reconciles the deducted figures to the net profit only in its hover", async () => {
    const figures = makeSaleProfitability();

    expect(
      Number(figures.gross_revenue) -
        Number(figures.item_price_total) -
        Number(figures.purchase_expenses) -
        Number(figures.business_expenses),
    ).toBe(Number(figures.net_profit));

    renderSummary();
    await openHint("netProfit");

    expect(screen.getByText(/Gross Revenue: 300\./)).toBeInTheDocument();
    expect(screen.getByText(/Purchase Cost: 100\./)).toBeInTheDocument();
    expect(screen.getByText(/Purchase Expenses: 20\./)).toBeInTheDocument();
    expect(screen.getByText(/Estimated OpEx: 30\./)).toBeInTheDocument();
  });

  it("charges OpEx in the net profit hover and nowhere as a term", async () => {
    renderSummary();

    expect(term("opEx")).toBeNull();
    expect(within(card()).queryByText("OpEx")).not.toBeInTheDocument();

    const values = [...card().querySelectorAll(".economics_snapshot__value")].map(
      (element) => element.textContent,
    );

    expect(values).not.toContain("30");

    await openHint("netProfit");

    expect(screen.getByText(/Estimated OpEx: 30\./)).toBeInTheDocument();
  });

  it("states the OpEx figure as zero when no overheads were estimated", async () => {
    renderSummary({ business_expenses: null });

    await openHint("netProfit");

    expect(screen.getByText(/Estimated OpEx: 0\./)).toBeInTheDocument();
  });

  it.each(["Outstanding", "Refunded", "COGS", "OpEx", "Projected"])(
    "carries no %s label",
    (label) => {
      renderSummary();

      expect(within(card()).queryByText(label)).not.toBeInTheDocument();
    },
  );

  it.each(["outstanding", "refunded", "cogs", "opEx", "projectedTotal", "projectedNetProfit"])(
    "states no %s term",
    (anchor) => {
      renderSummary();

      expect(term(anchor)).toBeNull();
    },
  );

  it("names the shipping and direct-expense split behind the purchase expenses figure", async () => {
    renderSummary({
      purchase_expenses: "700",
      purchase_shipping_cost: "695",
      direct_expenses: "5",
    });

    await openHint("purchaseExpenses");

    expect(screen.getByText(/695 in Shipping, plus 5 in Direct expenses/)).toBeInTheDocument();
  });

  it("claims no split when no direct expenses were recorded", async () => {
    renderSummary({
      purchase_expenses: "700",
      purchase_shipping_cost: "700",
      direct_expenses: null,
    });

    await openHint("purchaseExpenses");

    expect(screen.queryByText(/in Shipping, plus/)).not.toBeInTheDocument();
  });

  it("names the two halves behind today's cash", async () => {
    renderSummary();

    await openHint("cashPositionToday");

    expect(screen.getByText(/Collected and kept: 100\./)).toBeInTheDocument();
    expect(screen.getByText(/Paid to suppliers: 60\./)).toBeInTheDocument();
  });

  it("takes a label with a blank figure rather than heading an empty space", () => {
    renderSummary({ purchase_expenses: null });

    expect(term("purchaseExpenses")).toBeNull();
    expect(within(card()).queryByText("Pur. Expenses")).not.toBeInTheDocument();
    expect(amount("grossRevenue")).toBe(300);
  });

  it("renders a negative net profit with matching label and value tones", () => {
    renderSummary({ net_profit: "-96" });

    expect(within(card()).getByText("Net Profit").parentElement).toHaveAttribute(
      "data-tone",
      "negative",
    );
    expect(within(card()).getByText("−96")).toHaveAttribute("data-tone", "negative");
  });

  it("tones a cash shortfall negative as well", () => {
    renderSummary({ cash_position: "-20" });

    expect(within(card()).getByText("Cash today").parentElement).toHaveAttribute(
      "data-tone",
      "negative",
    );
    expect(within(card()).getByText("−20")).toHaveAttribute("data-tone", "negative");
  });

  it("makes no profit claim when nothing was spent on the sale", () => {
    const { container } = renderSummary({
      item_price_total: null,
      purchase_expenses: null,
      purchase_shipping_cost: null,
      direct_expenses: null,
      business_expenses: null,
    });

    expect(container).toBeEmptyDOMElement();
  });

  it("makes no profit claim without a gross revenue to charge costs against", () => {
    const { container } = renderSummary({ gross_revenue: null });

    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing when the backend reports no summary", () => {
    const { container } = render(<ProfitabilitySummary profitability={null} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("makes each label the hover target with no asterisk mark", async () => {
    renderSummary();

    expect(card().querySelector(".tip_mark__trigger")).toBeNull();
    expect(within(card()).queryByLabelText("More information")).not.toBeInTheDocument();

    const user = userEvent.setup();
    await user.hover(within(card()).getByText("Gross Revenue"));
    await act(async () => {});

    expect(screen.getByText(/For this sale\./)).toBeInTheDocument();
  });

  it.each(TERM_ANCHORS)("points the %s label at its own glossary entry", async (anchor) => {
    renderSummary();

    await openHint(anchor);

    expect(screen.getByRole("link", { name: "Glossary" })).toHaveAttribute(
      "href",
      `/glossary#${anchor}`,
    );
  });

  describe("what the figures were added up from", () => {
    it("warns in a hint that a plan's figures cover every sale in it", async () => {
      renderSummary({ scope: "plan" });

      expect(card()).not.toHaveTextContent("payment plan");

      await openHint("grossRevenue");

      expect(screen.getByText(/Across every sale in this payment plan\./)).toBeInTheDocument();
    });

    it("makes no plan claim for a sale that stands alone", async () => {
      renderSummary({ scope: "sale" });

      await openHint("grossRevenue");

      expect(screen.queryByText(/payment plan/)).not.toBeInTheDocument();
      expect(screen.getByText(/For this sale\./)).toBeInTheDocument();
    });

    // Every figure is a sum. Without a scope note a reader cannot tell a sale
    // total from a line total from a product's lifetime total.
    it.each(TERM_ANCHORS)("closes the %s hint by naming what was added up", async (anchor) => {
      renderSummary({ scope: "sale" });

      await openHint(anchor);

      expect(screen.getByText(/For this sale\./)).toBeInTheDocument();
    });
  });
});

function renderSummary(overrides: Partial<SaleProfitabilityRecord> = {}) {
  return render(<ProfitabilitySummary profitability={makeSaleProfitability(overrides)} />);
}

function card() {
  return screen.getByTestId("sale-profitability-card");
}

function term(anchor: string): HTMLElement | null {
  return screen.queryByTestId(`metric-${anchor}`);
}

function termOrFail(anchor: string): HTMLElement {
  return screen.getByTestId(`metric-${anchor}`);
}

// An operator or arrow was an element holding nothing but a glyph. A negative
// amount reads "−96", so matching the whole content tells the two apart.
function operatorGlyphs(): string[] {
  return [...card().querySelectorAll("*")]
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
