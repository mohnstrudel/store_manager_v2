import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import PlanProgressBar from "./PlanProgressBar";
import { makeSalePaymentPlan } from "@/test/factories";

describe("PlanProgressBar", () => {
  // Four-part plan of 255 each, contract value 1 020, two charges collected,
  // viewed from the second charge — the ticket's worked example.
  it("renders one segment per expected charge, fills the collected ones, and marks the current segment", () => {
    const { container } = render(
      <PlanProgressBar
        plan={makeSalePaymentPlan({
          expected_parts: 4,
          collected_parts: 2,
          sale_part_number: 2,
          is_origin_sale: false,
          projected_total: "1 020 EUR",
          projected_collected: "510 EUR",
        })}
      />,
    );

    const segments = container.querySelectorAll(".plan_progress_bar__segment");
    expect(segments).toHaveLength(4);

    const filled = container.querySelectorAll(".plan_progress_bar__segment[data-filled]");
    expect(filled).toHaveLength(2);
    expect(filled[0]).toBe(segments[0]);
    expect(filled[1]).toBe(segments[1]);
  });

  it("distinguishes the current segment by more than its fill color", () => {
    const { container } = render(
      <PlanProgressBar
        plan={makeSalePaymentPlan({
          expected_parts: 4,
          collected_parts: 2,
          sale_part_number: 2,
          is_origin_sale: false,
        })}
      />,
    );

    const segments = container.querySelectorAll(".plan_progress_bar__segment");
    // The current segment carries its own DOM marker (a non-color cue for
    // sighted users via CSS, and readable text for assistive tech) rather
    // than relying on the fill color alone to say which charge this is.
    expect(segments[1]).toHaveAttribute("data-current");
    expect(segments[0]).not.toHaveAttribute("data-current");
    expect(segments[2]).not.toHaveAttribute("data-current");
    expect(screen.getByText("This payment")).toBeInTheDocument();
  });

  it("states the charge's position and how much of the contract value has been collected", () => {
    render(
      <PlanProgressBar
        plan={makeSalePaymentPlan({
          expected_parts: 4,
          collected_parts: 2,
          sale_part_number: 2,
          is_origin_sale: false,
          projected_total: "1 020 EUR",
          projected_collected: "510 EUR",
        })}
      />,
    );

    expect(screen.getByText("Payment 2 of 4 · 510 EUR of 1 020 EUR collected")).toBeInTheDocument();
  });

  it("omits the money part of the caption when the contract value is unknown, but still renders position", () => {
    render(
      <PlanProgressBar
        plan={makeSalePaymentPlan({
          expected_parts: 4,
          collected_parts: 2,
          sale_part_number: 2,
          is_origin_sale: false,
          projected_total: null,
          projected_collected: null,
        })}
      />,
    );

    expect(screen.getByText("Payment 2 of 4")).toBeInTheDocument();
    expect(screen.queryByText(/collected/)).not.toBeInTheDocument();

    const segments = document.querySelectorAll(".plan_progress_bar__segment");
    expect(segments).toHaveLength(4);
  });

  it("names the amount instead of leaving a blank when nothing of the contract has been collected yet", () => {
    render(
      <PlanProgressBar
        plan={makeSalePaymentPlan({
          expected_parts: 4,
          collected_parts: 0,
          sale_part_number: 1,
          is_origin_sale: true,
          projected_total: "1 020 EUR",
          projected_collected: null,
        })}
      />,
    );

    expect(screen.getByText("Payment 1 of 4 · n/p of 1 020 EUR collected")).toBeInTheDocument();
  });

  it("renders nothing when the plan cannot place this sale within it", () => {
    const { container } = render(
      <PlanProgressBar plan={makeSalePaymentPlan({ sale_part_number: null })} />,
    );

    expect(container).toBeEmptyDOMElement();
  });
});
