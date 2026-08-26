import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makeSalePaymentPlan, makeSalePaymentProgress } from "@/test/factories";

import PaymentPlanMarker from "./PaymentPlanMarker";

describe("PaymentPlanMarker", () => {
  it("renders nothing for a paid sale", () => {
    const { container } = render(<PaymentPlanMarker progress={null} settlementStatus="paid" />);

    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing for an unknown settlement", () => {
    const { container } = render(<PaymentPlanMarker progress={null} settlementStatus="unknown" />);

    expect(container).toBeEmptyDOMElement();
  });

  it("renders nothing for an excluded sale", () => {
    const { container } = render(<PaymentPlanMarker progress={null} settlementStatus={null} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("falls back to the bare status when a not-fully-paid sale carries no progress data", () => {
    render(<PaymentPlanMarker progress={null} settlementStatus="not_fully_paid" />);

    expect(screen.getByText("Not fully paid")).toBeInTheDocument();
  });

  it("marks a Seal deposit's collected percentage and projected total", () => {
    render(
      <PaymentPlanMarker
        progress={makeSalePaymentProgress({ source: "plan_deposit", percent: 42, total: "$245" })}
        settlementStatus="not_fully_paid"
      />,
    );

    expect(screen.getByText("Deposit · 42% collected · Projected total $245")).toBeInTheDocument();
  });

  it("marks a scheduled follow-up's position, collected percentage, and projected total", () => {
    render(
      <PaymentPlanMarker
        progress={makeSalePaymentProgress({
          source: "plan_schedule",
          percent: 42,
          total: "$245",
          sale_part_number: 2,
          expected_parts: 8,
        })}
        settlementStatus="not_fully_paid"
      />,
    );

    expect(
      screen.getByText("Payment 2 of 8 · 42% collected · Projected total $245"),
    ).toBeInTheDocument();
  });

  it("marks an amount-only sale's collected percentage and total", () => {
    render(
      <PaymentPlanMarker
        progress={makeSalePaymentProgress({ source: "amount", percent: 42, total: "$245" })}
        settlementStatus="not_fully_paid"
      />,
    );

    expect(screen.getByText("Not fully paid · 42% collected · Total $245")).toBeInTheDocument();
  });

  it("marks a Woo verified deposit's collected amount and total, with no percentage", () => {
    render(
      <PaymentPlanMarker
        progress={makeSalePaymentProgress({ source: "woo_deposit", paid: "$196", total: "$1,145" })}
        settlementStatus="not_fully_paid"
      />,
    );

    expect(
      screen.getByText("Not fully paid · Deposit $196 collected · Total $1,145"),
    ).toBeInTheDocument();
  });

  it("marks a Woo partial without plugin deposit evidence as unavailable, never a fabricated percentage", () => {
    render(
      <PaymentPlanMarker
        progress={makeSalePaymentProgress({ source: "woo_unavailable" })}
        settlementStatus="not_fully_paid"
      />,
    );

    expect(screen.getByText("Not fully paid · Payment amounts unavailable")).toBeInTheDocument();
  });
  it("keeps the originating sale link visible for a follow-up payment", () => {
    render(
      <PaymentPlanMarker
        plans={[
          makeSalePaymentPlan({
            origin_sale: { path: "/sales/9", identifier: "HSCM#1746" },
          }),
        ]}
        progress={makeSalePaymentProgress({
          source: "plan_schedule",
          percent: 42,
          total: "$245",
          sale_part_number: 2,
          expected_parts: 8,
        })}
        settlementStatus="not_fully_paid"
      />,
    );

    expect(screen.getByRole("link", { name: "Original sale HSCM#1746" })).toHaveAttribute(
      "href",
      "/sales/9",
    );
  });
});
