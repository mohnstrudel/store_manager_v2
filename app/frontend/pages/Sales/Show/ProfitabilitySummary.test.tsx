import { act, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import ProfitabilitySummary from "./ProfitabilitySummary";
import { makeSaleProfitability } from "../test/factories";
import type { SaleProfitabilityRecord } from "../types";

describe("Sales/Show/ProfitabilitySummary", () => {
  it("states its terms without an operator or arrow between them", () => {
    renderSummary({ expected_final_profit: "-96" });

    expect(operatorGlyphs()).toEqual([]);
    // The minus on a negative amount is part of the figure, not an operator.
    expect(within(card()).getByText("−96")).toBeInTheDocument();
  });

  it("charges one cost figure, never the merchandise split it is made of", () => {
    renderSummary({ purchase_cost: "2 700", merchandise_cost: "2 400", direct_expenses: "300" });

    expect(amount("cogs")).toBe(2700);
    expect(screen.queryByText("Merchandise")).not.toBeInTheDocument();
    expect(screen.queryByText("Direct")).not.toBeInTheDocument();
  });

  it("states an equation whose deducted terms reconcile to the net profit", () => {
    renderSummary({
      expected_revenue: "5 000",
      purchase_cost: "2 700",
      business_expenses: "500",
      expected_final_profit: "1 800",
    });

    expect(amount("revenue")).toBe(5000);
    expect(amount("cogs")).toBe(2700);
    expect(amount("opEx")).toBe(500);
    expect(amount("netProfit")).toBe(1800);
    expect(amount("revenue") - amount("cogs") - amount("opEx")).toBe(amount("netProfit"));
  });

  it("names the OpEx term without repeating the rate it came from", () => {
    renderSummary({ expense_rate_percent: 35, business_expenses: "500" });

    expect(within(card()).getByText("OpEx")).toBeInTheDocument();
    expect(card()).not.toHaveTextContent("35%");
  });

  it("states what is still owed and what was paid back as figures of their own", () => {
    renderSummary({
      received_revenue: "100",
      outstanding_revenue: "200",
      refunded_revenue: "40",
    });

    expect(amount("outstanding")).toBe(200);
    expect(amount("refunded")).toBe(40);
  });

  // A sale is billed and collected as one amount, so Received repeats
  // Revenue for all but a handful of sales; Outstanding names the gap when
  // they part. The product card keeps Received, where they genuinely differ.
  it("does not restate the revenue as money received", () => {
    renderSummary({ expected_revenue: "377", received_revenue: "377" });

    expect(term("received")).toBeNull();
    expect(screen.queryByText("Received")).not.toBeInTheDocument();
    expect(amount("revenue")).toBe(377);
  });

  describe("a figure that is zero or absent", () => {
    it("takes its label with it rather than heading an empty space", () => {
      renderSummary({ refunded_revenue: null, outstanding_revenue: null });

      expect(term("refunded")).toBeNull();
      expect(term("outstanding")).toBeNull();
      expect(screen.queryByText("Refunded")).not.toBeInTheDocument();
      expect(screen.queryByText("Outstanding")).not.toBeInTheDocument();
      expect(amount("revenue")).toBeGreaterThan(0);
    });

    it("drops the OpEx term when no rate is configured", () => {
      renderSummary({ expense_rate_percent: 0, business_expenses: null });

      expect(term("opEx")).toBeNull();
      expect(screen.queryByText("OpEx")).not.toBeInTheDocument();
    });

    it("drops the cost term when nothing was spent but overheads were estimated", () => {
      renderSummary({ purchase_cost: null, business_expenses: "45" });

      expect(term("cogs")).toBeNull();
      expect(amount("opEx")).toBe(45);
    });
  });

  it("renders a negative net profit with matching label and value tones", () => {
    renderSummary({ expected_final_profit: "-96" });

    expect(within(card()).getByText("Net Profit").parentElement).toHaveAttribute(
      "data-tone",
      "negative",
    );
    expect(within(card()).getByText("−96")).toHaveAttribute("data-tone", "negative");
  });

  it("makes no profit claim when nothing was spent on the sale", () => {
    const { container } = renderSummary({
      purchase_cost: null,
      merchandise_cost: null,
      direct_expenses: null,
      business_expenses: null,
    });

    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing when the backend reports no summary", () => {
    const { container } = render(<ProfitabilitySummary profitability={null} />);

    expect(container).toBeEmptyDOMElement();
  });

  describe("the caveats that used to be captions", () => {
    it("names the merchandise and direct-expense split behind the single cost figure", async () => {
      renderSummary({ purchase_cost: "700", merchandise_cost: "695", direct_expenses: "5" });

      await openHint("cogs");

      expect(screen.getByText(/695 merchandise cost plus 5 direct expenses/)).toBeInTheDocument();
    });

    it("claims no split when no direct expenses were recorded", async () => {
      renderSummary({ purchase_cost: "700", merchandise_cost: "700", direct_expenses: null });

      await openHint("cogs");

      expect(screen.queryByText(/merchandise cost plus/)).not.toBeInTheDocument();
    });

    it("warns in the revenue hint that the figures cover the whole payment plan", async () => {
      renderSummary({ scope: "plan", projected_final_profit: null });

      expect(card()).not.toHaveTextContent("payment plan");

      await openHint("revenue");

      expect(screen.getByText(/Across every sale in this payment plan\./)).toBeInTheDocument();
    });

    // Revenue and COGS count what has been billed and spent, so the scope note
    // must not claim they include charges nobody has raised yet. Only the
    // Projected terms do, and their own hints say so.
    it("keeps unraised charges out of the scope note, and in the projected hint", async () => {
      renderSummary({ scope: "plan", projected_final_profit: "167", projected_revenue: "1 020" });

      await openHint("revenue");
      expect(screen.queryByText(/including charges not yet raised/)).not.toBeInTheDocument();
      expect(screen.getByText(/Across every sale in this payment plan\./)).toBeInTheDocument();

      await openHint("projectedTotal");
      expect(screen.getByText(/once every scheduled charge has been raised/)).toBeInTheDocument();
    });

    it("makes no plan claim for a sale that stands alone", async () => {
      renderSummary({ scope: "sale" });

      await openHint("revenue");

      expect(screen.queryByText(/payment plan/)).not.toBeInTheDocument();
      expect(screen.getByText(/For this sale\./)).toBeInTheDocument();
    });

    // Every figure is a sum. Without a scope note a reader cannot tell an
    // sale total from a line total from a product's lifetime total.
    it.each(["cogs", "opEx", "netProfit", "outstanding"])(
      "closes the %s hint by naming what was added up",
      async (anchor) => {
        renderSummary({ scope: "sale", outstanding_revenue: "200" });

        await openHint(anchor);

        expect(screen.getByText(/For this sale\./)).toBeInTheDocument();
      },
    );
  });

  // Worked example from the spec: a 30% deposit on a 1 020 deal, the remaining
  // charges not yet raised, at a 15% OpEx rate.
  describe("the projected figures", () => {
    const bookedAndProjected = {
      scope: "plan" as const,
      expected_revenue: "300",
      merchandise_cost: "700",
      direct_expenses: null,
      purchase_cost: "700",
      business_expenses: "45",
      expected_final_profit: "-445",
      expense_rate_percent: 15,
      projected_revenue: "1 020",
      projected_business_expenses: "153",
      projected_final_profit: "167",
    };

    it("gives every projected figure a label of its own", () => {
      renderSummary(bookedAndProjected);

      expect(amount("revenue")).toBe(300);
      expect(amount("projectedTotal")).toBe(1020);
      expect(amount("opEx")).toBe(45);
      expect(amount("projectedOpEx")).toBe(153);
      expect(amount("netProfit")).toBe(-445);
      expect(amount("projectedNetProfit")).toBe(167);

      for (const anchor of ["projectedTotal", "projectedOpEx", "projectedNetProfit"]) {
        expect(within(termOrFail(anchor)).getByText("Projected")).toBeInTheDocument();
      }
    });

    it("points each projected label at its own glossary entry", async () => {
      renderSummary(bookedAndProjected);

      await openHint("projectedNetProfit");

      expect(screen.getByRole("link", { name: "Glossary" })).toHaveAttribute(
        "href",
        "/glossary#projectedNetProfit",
      );
    });

    it("keeps a projected figure in the same group as the figure it projects", () => {
      renderSummary(bookedAndProjected);

      expect(group("revenue")).toBe(group("projectedTotal"));
      expect(group("opEx")).toBe(group("projectedOpEx"));
      expect(group("netProfit")).toBe(group("projectedNetProfit"));
      expect(group("revenue")).not.toBe(group("cogs"));
    });

    it("states the cost once, since the same spend backs both bases", () => {
      renderSummary(bookedAndProjected);

      expect(amount("cogs")).toBe(700);
      expect(screen.getAllByText("COGS")).toHaveLength(1);
    });

    it("reconciles each basis against that one cost figure", () => {
      renderSummary(bookedAndProjected);

      expect(amount("revenue") - amount("cogs") - amount("opEx")).toBe(amount("netProfit"));
      expect(amount("projectedTotal") - amount("cogs") - amount("projectedOpEx")).toBe(
        amount("projectedNetProfit"),
      );
    });

    it("computes the projected OpEx from the projected revenue, not the booked business expenses", () => {
      renderSummary(bookedAndProjected);

      // Reusing the booked 45.00 OpEx for the projected basis would report
      // 175.00 profit instead of 167.00 — pin the real, larger OpEx figure.
      expect(amount("projectedOpEx")).toBe(153);
      expect(amount("projectedOpEx")).not.toBe(45);
      expect(amount("projectedNetProfit")).not.toBe(175);
    });

    it("tones a booked loss and a projected gain apart", () => {
      renderSummary(bookedAndProjected);

      expect(within(termOrFail("netProfit")).getByText("−445")).toHaveAttribute(
        "data-tone",
        "negative",
      );
      expect(within(termOrFail("projectedNetProfit")).getByText("167")).toHaveAttribute(
        "data-tone",
        "positive",
      );
    });

    it("shows no projection for a plan with no known contract value", () => {
      renderSummary({ scope: "plan" });

      expect(term("projectedTotal")).toBeNull();
      expect(term("projectedNetProfit")).toBeNull();
      expect(screen.queryByText("Projected")).not.toBeInTheDocument();
    });

    it("shows no projection for a sale outside a plan", () => {
      renderSummary({ scope: "sale" });

      expect(term("projectedTotal")).toBeNull();
      expect(screen.queryByText("Projected")).not.toBeInTheDocument();
    });
  });
});

function renderSummary(overrides: Partial<SaleProfitabilityRecord> = {}) {
  return render(<ProfitabilitySummary profitability={makeSaleProfitability(overrides)} />);
}

function card() {
  return screen.getByTestId("sale-profitability-card");
}

// Three terms are labelled "Projected", so each is addressed by the glossary
// anchor that says which figure it states rather than by its label text.
function term(anchor: string): HTMLElement | null {
  return screen.queryByTestId(`metric-${anchor}`);
}

function termOrFail(anchor: string): HTMLElement {
  return screen.getByTestId(`metric-${anchor}`);
}

function group(anchor: string): Element | null {
  return termOrFail(anchor).closest(".economics_snapshot__group");
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

  await user.hover(within(termOrFail(anchor)).getByLabelText("More information"));
  await act(async () => {});
}
