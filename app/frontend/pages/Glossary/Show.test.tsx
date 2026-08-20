import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Show, { sections } from "./Show";

const entries = sections.flatMap((section) => section.entries);

describe("Glossary/Show", () => {
  it("renders the page heading", () => {
    render(<Show />);

    expect(screen.getByRole("heading", { name: "Money glossary" })).toBeInTheDocument();
  });

  it("gives every term that the app's tooltips link to a matching anchor", () => {
    const { container } = render(<Show />);

    const anchors = [
      "revenue",
      "monthlyRevenue",
      "outstanding",
      "cogs",
      "directExpenses",
      "opEx",
      "estimatedOpEx",
      "projectedOpEx",
      "actualOpEx",
      "comparison",
      "netProfit",
      "expectedNetProfit",
      "cashPositionToday",
      "projectedNetProfit",
      "projectedTotal",
      "potentialSales",
      "expectedTotalCost",
      "variantPurchaseCostTotal",
      "variantTheoreticalProfit",
    ];

    for (const anchor of anchors) {
      expect(container.querySelector(`#${anchor}`)).not.toBeNull();
    }
  });

  it("defines Revenue and explains how cancellations affect it", () => {
    render(<Show />);

    expect(
      screen.getByText("The full value of a customer's order, whether or not they have paid yet."),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/A cancelled order drops out of Revenue everywhere/),
    ).toBeInTheDocument();
  });

  it("groups terms into sections and links to each one from the jump list", () => {
    render(<Show />);

    const sections = [
      ["Money from customers", "money-from-customers"],
      ["What the goods cost", "what-the-goods-cost"],
      ["Overheads", "overheads"],
      ["Profit", "profit"],
      ["Stock and suppliers", "stock-and-suppliers"],
    ];
    const navigation = screen.getByRole("navigation", { name: "Glossary sections" });

    for (const [title, id] of sections) {
      expect(screen.getByRole("heading", { level: 2, name: title })).toHaveAttribute("id", id);
      expect(within(navigation).getByRole("link", { name: title })).toHaveAttribute(
        "href",
        `#${id}`,
      );
    }
  });

  it("keeps each section's terms in the manager's reading order", () => {
    render(<Show />);

    const expectedTerms = {
      "Money from customers": [
        "Revenue",
        "Potential sales",
        "Outstanding",
        "Refunded",
        "Payment plan",
        "Deposit",
        "Payment",
        "Projected total",
      ],
      "What the goods cost": ["COGS", "Direct expenses"],
      Overheads: ["OpEx", "OpEx rates", "Actual OpEx", "Comparison"],
      Profit: ["Net profit", "Expected net profit", "Cash position today", "Projected net profit"],
      "Stock and suppliers": [
        "Expected total cost",
        "List cost",
        "Total landed cost",
        "Theoretical profit",
        "Supplier debt",
        "Unit shortfall",
        "Products short",
      ],
    };

    for (const [sectionName, terms] of Object.entries(expectedTerms)) {
      const section = screen.getByRole("region", { name: sectionName });

      expect(
        within(section)
          .getAllByRole("term")
          .map((term) => term.textContent),
      ).toEqual(terms);
    }
  });

  it("distinguishes stock cost terms and profit timing", () => {
    render(<Show />);

    expect(screen.getByText(/not a record of what was actually spent/)).toBeInTheDocument();
    expect(screen.getByText(/no connection to Total landed cost/)).toBeInTheDocument();
    expect(
      screen.getByText(/tied only to the product rather than to a variant/),
    ).toBeInTheDocument();
    expect(
      screen.getByText(/money went out to a supplier before any came back/),
    ).toBeInTheDocument();
  });

  it("distinguishes the dashboard's two shortfall counts", () => {
    render(<Show />);

    expect(screen.getByText(/number of units sold beyond the number bought/)).toBeInTheDocument();
    expect(
      screen.getByText(/number of product rows on the dashboard that have a Unit shortfall/),
    ).toBeInTheDocument();
  });

  it("names the interface label for Supplier debt without repeating the term", () => {
    render(<Show />);

    expect(screen.getByText("Shown as “Debt” on the suppliers list")).toBeInTheDocument();
    expect(screen.queryByText(/Shown as “Supplier debt”/)).toBeNull();
  });

  it("explains the two meanings of OpEx and Payment", () => {
    render(<Show />);

    expect(
      screen.getByText(/The “OpEx” navigation item opens the records behind Actual OpEx/),
    ).toBeInTheDocument();
    expect(screen.getByText(/“OpEx” on a sale or product card is an estimate/)).toBeInTheDocument();
    expect(
      screen.getByText(/“Payments” on a purchase are payments to a supplier/),
    ).toBeInTheDocument();
  });

  it("calls out the figures most likely to mislead a manager", () => {
    render(<Show />);

    expect(screen.getByText(/no purchase item linked shows no cost/)).toBeInTheDocument();
    expect(screen.getByText(/recalculates Estimated OpEx and Comparison/)).toBeInTheDocument();
    expect(screen.getByText(/A purchase not yet received is not counted/)).toBeInTheDocument();
    expect(screen.getByText(/describes no actual sale/)).toBeInTheDocument();
    expect(
      screen.getByText(/a deposit carrying the whole job's cost can show a loss/),
    ).toBeInTheDocument();
  });

  it("tells the deposit-versus-plan profit story once, on Net profit", () => {
    render(<Show />);

    expect(
      screen.getAllByText(/Projected net profit reads the same job as a finished deal/),
    ).toHaveLength(1);
  });

  it("gives the new terms their own anchors", () => {
    const { container } = render(<Show />);

    expect(container.querySelector("#paymentPlan")).not.toBeNull();
    expect(container.querySelector("#deposit")).not.toBeNull();
    expect(container.querySelector("#productsShort")).not.toBeNull();
  });

  it("keeps aliases unique and attached to the term they describe", () => {
    const { container } = render(<Show />);
    const aliases = {
      monthlyRevenue: "revenue",
      estimatedOpEx: "opEx",
      projectedOpEx: "opEx",
    };

    for (const [alias, entry] of Object.entries(aliases)) {
      expect(container.querySelectorAll(`#${alias}`)).toHaveLength(1);
      expect(container.querySelector(`#${alias}`)?.closest(`#${entry}`)).not.toBeNull();
    }
  });

  it("gives Actual OpEx and Comparison their own unique anchors", () => {
    const { container } = render(<Show />);

    for (const id of ["actualOpEx", "comparison"]) {
      expect(container.querySelectorAll(`#${id}`)).toHaveLength(1);
    }
  });

  it("distinguishes the three Projected figures on a sale card", () => {
    render(<Show />);

    expect(screen.getByText(/Shown as “Projected” in the Revenue row/)).toBeInTheDocument();
    expect(screen.getByText(/“Projected” in the OpEx row/)).toBeInTheDocument();
    expect(screen.getByText(/Shown as “Projected” in the Net Profit row/)).toBeInTheDocument();
  });

  it("names an on-screen label only where it differs from the term", () => {
    for (const entry of entries) {
      for (const { labels, where } of entry.shownAs ?? []) {
        expect(labels.length).toBeGreaterThan(0);
        expect(where).not.toBe("");

        for (const label of labels) {
          expect(label.toLowerCase()).not.toBe(entry.term.toLowerCase());
        }
      }
    }
  });
});
