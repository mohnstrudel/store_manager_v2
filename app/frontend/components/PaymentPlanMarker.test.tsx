import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makeSalePaymentPlan } from "@/test/factories";

import PaymentPlanMarker, { isFollowUpPayment } from "./PaymentPlanMarker";

describe("PaymentPlanMarker", () => {
  it("renders nothing for a sale that belongs to no plan", () => {
    const { container } = render(<PaymentPlanMarker plans={[]} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("states the position of a follow-up payment and links back to the original sale", () => {
    render(
      <PaymentPlanMarker
        plans={[
          makeSalePaymentPlan({
            expected_parts: 4,
            is_origin_sale: false,
            sale_part_number: 2,
            origin_sale: { path: "/sales/1", identifier: "HSCM#1746" },
          }),
        ]}
      />,
    );

    expect(screen.getByText("Payment 2 of 4")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Original sale HSCM#1746" })).toHaveAttribute(
      "href",
      "/sales/1",
    );
  });

  it("marks the originating sale as carrying a plan and does not link it to itself", () => {
    render(
      <PaymentPlanMarker
        plans={[makeSalePaymentPlan({ collected_parts: 3, expected_parts: 8 })]}
      />,
    );

    expect(screen.getByText("Payment plan · 3 of 8 collected")).toBeInTheDocument();
    expect(screen.queryByRole("link")).not.toBeInTheDocument();
  });

  it("appends the projected total to an instalment plan's collected count", () => {
    render(
      <PaymentPlanMarker
        plans={[
          makeSalePaymentPlan({
            kind: "installments",
            collected_parts: 2,
            expected_parts: 4,
            projected_total: "1 020 EUR",
          }),
        ]}
      />,
    );

    expect(
      screen.getByText("Payment plan · 2 of 4 collected · Projected total 1 020 EUR"),
    ).toBeInTheDocument();
  });

  it("appends the projected total to a later payment's position in the plan", () => {
    render(
      <PaymentPlanMarker
        plans={[
          makeSalePaymentPlan({
            kind: "payment_terms",
            is_origin_sale: false,
            sale_part_number: 2,
            expected_parts: 4,
            projected_total: "1 020 EUR",
            origin_sale: { path: "/sales/1", identifier: "HSCM#1746" },
          }),
        ]}
      />,
    );

    expect(screen.getByText("Payment 2 of 4 · Projected total 1 020 EUR")).toBeInTheDocument();
  });

  it("names a deposit and its projection instead of a one-of-one fraction", () => {
    render(
      <PaymentPlanMarker
        plans={[
          makeSalePaymentPlan({
            kind: "deposit",
            expected_parts: 1,
            collected_parts: 1,
            deposit_percent: 30,
            projected_total: "1 020 EUR",
          }),
        ]}
      />,
    );

    expect(
      screen.getByText(/30% deposit collected · Projected total 1\s020 EUR/),
    ).toBeInTheDocument();
    expect(screen.queryByText(/1 of 1/)).not.toBeInTheDocument();
  });

  it("marks itself as a follow-up only when the sale is a later payment", () => {
    const { rerender, container } = render(<PaymentPlanMarker plans={[makeSalePaymentPlan()]} />);

    expect(container.querySelector(".payment_plan_marker")).not.toHaveAttribute("data-follow-up");

    rerender(
      <PaymentPlanMarker
        plans={[makeSalePaymentPlan({ is_origin_sale: false, sale_part_number: 2 })]}
      />,
    );

    expect(container.querySelector(".payment_plan_marker")).toHaveAttribute("data-follow-up");
  });

  it("renders every plan a sale belongs to", () => {
    render(
      <PaymentPlanMarker
        plans={[
          makeSalePaymentPlan({ id: 1, collected_parts: 3, expected_parts: 8 }),
          makeSalePaymentPlan({
            id: 2,
            kind: "deposit",
            deposit_percent: 30,
            collected_parts: 0,
            expected_parts: 1,
          }),
        ]}
      />,
    );

    expect(screen.getByText("Payment plan · 3 of 8 collected")).toBeInTheDocument();
    expect(screen.getByText("30% deposit")).toBeInTheDocument();
  });
});

describe("isFollowUpPayment", () => {
  it("is false without plans and for the originating sale", () => {
    expect(isFollowUpPayment([])).toBe(false);
    expect(isFollowUpPayment([makeSalePaymentPlan()])).toBe(false);
  });

  it("is true when any plan places the sale after the original order", () => {
    expect(
      isFollowUpPayment([makeSalePaymentPlan({ is_origin_sale: false, sale_part_number: 2 })]),
    ).toBe(true);
  });
});
