import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { PaymentProgress } from "@/types/payment";

import PaymentProgressBar from "./PaymentProgressBar";

describe("PaymentProgressBar", () => {
  describe("progress bar", () => {
    it("renders the progress percentage when progress is between 0 and 100", () => {
      renderPaymentProgressBar({ progress: { ...baseProgress, progress: 60 } });

      expect(screen.getByText("60%")).toBeInTheDocument();
    });

    it("hides the progress fill when progress is 0", () => {
      const { container } = renderPaymentProgressBar({
        progress: { ...baseProgress, progress: 0 },
      });

      expect(container.querySelector(".rounded-full")).not.toBeInTheDocument();
    });

    it("hides the progress fill when progress exceeds 100", () => {
      const { container } = renderPaymentProgressBar({
        progress: { ...baseProgress, progress: 110 },
      });

      expect(container.querySelector(".rounded-full")).not.toBeInTheDocument();
    });
  });

  describe('when caption is "full" (default)', () => {
    it("shows paid, price, and debt when progress is incomplete", () => {
      renderPaymentProgressBar({
        progress: { progress: 25, paid: "50", price: "200", debt: "150" },
      });

      expect(screen.getByText("50")).toBeInTheDocument();
      expect(screen.getByText("200")).toBeInTheDocument();
      expect(screen.getByText("150")).toBeInTheDocument();
    });

    it("hides the detail row when fully paid", () => {
      renderPaymentProgressBar({
        progress: { progress: 100, paid: "200", price: "200", debt: "0" },
      });

      expect(screen.queryByText("200")).not.toBeInTheDocument();
    });

    it("shows 'n/p' when paid is empty", () => {
      renderPaymentProgressBar({
        progress: { progress: 50, paid: "", price: "100", debt: "50" },
      });

      expect(screen.getByText("n/p")).toBeInTheDocument();
    });

    it("names an unknown split instead of claiming nothing was paid", () => {
      renderPaymentProgressBar({
        progress: { progress: 0, paid: null, price: "992", debt: null, amounts_unknown: true },
      });

      expect(screen.getAllByText("unknown")).toHaveLength(2);
      expect(screen.getByText("992")).toBeInTheDocument();
      expect(screen.queryByText("n/p")).not.toBeInTheDocument();
    });

    it("shows 'n/p' when nothing was received, so the server sends no paid amount", () => {
      renderPaymentProgressBar({
        progress: { progress: 0, paid: null, price: "1 000", debt: "1 000" },
      });

      expect(screen.getByText("n/p")).toBeInTheDocument();
      // Price and debt are the same amount while nothing has been received.
      expect(screen.getAllByText("1 000")).toHaveLength(2);
    });
  });

  describe('when caption is "debtOnly"', () => {
    it("shows only the debt amount when payment is incomplete", () => {
      renderPaymentProgressBar({
        caption: "debtOnly",
        progress: { progress: 25, paid: "50.00", price: "200.00", debt: "150.00" },
      });

      expect(screen.getByText("150.00 debt")).toBeInTheDocument();
      expect(screen.queryByText("50.00")).not.toBeInTheDocument();
    });

    it("hides the debt section when fully paid", () => {
      renderPaymentProgressBar({
        caption: "debtOnly",
        progress: { progress: 100, paid: "200", price: "200", debt: "0" },
      });

      expect(screen.queryByText(/debt/)).not.toBeInTheDocument();
    });

    it("hides the debt section when the server sends no debt amount", () => {
      renderPaymentProgressBar({
        caption: "debtOnly",
        progress: { progress: 40, paid: null, price: null, debt: null },
      });

      expect(screen.queryByText(/debt/)).not.toBeInTheDocument();
    });
  });

  describe('when caption is "paidOfTotal"', () => {
    it("shows the paid amount of the total when payment is incomplete", () => {
      renderPaymentProgressBar({
        caption: "paidOfTotal",
        progress: { progress: 25, paid: "50.00", price: "200.00", debt: "150.00" },
      });

      expect(screen.getByText("50.00 of 200.00")).toBeInTheDocument();
      expect(screen.queryByText(/debt/)).not.toBeInTheDocument();
    });

    it("hides the caption when fully paid", () => {
      renderPaymentProgressBar({
        caption: "paidOfTotal",
        progress: { progress: 100, paid: "200", price: "200", debt: "0" },
      });

      expect(screen.queryByText(/of/)).not.toBeInTheDocument();
    });

    it("names the unpaid case instead of leading with a blank when nothing was received", () => {
      renderPaymentProgressBar({
        caption: "paidOfTotal",
        progress: { progress: 0, paid: null, price: "1 000", debt: "1 000" },
      });

      expect(screen.getByText("n/p of 1 000")).toBeInTheDocument();
    });

    it("names an unknown split rather than the outstanding total the server had to guess", () => {
      renderPaymentProgressBar({
        caption: "paidOfTotal",
        progress: { progress: 0, paid: null, price: "623", debt: "623", amounts_unknown: true },
      });

      expect(screen.getByText("unknown of 623")).toBeInTheDocument();
    });

    it("drops the 'of' phrase when the total is unknown", () => {
      renderPaymentProgressBar({
        caption: "paidOfTotal",
        progress: { progress: 0, paid: null, price: null, debt: null },
      });

      expect(screen.getByText("n/p")).toBeInTheDocument();
      expect(screen.queryByText(/of/)).not.toBeInTheDocument();
    });
  });
});

const baseProgress: PaymentProgress = {
  progress: 50,
  paid: "50",
  price: "100",
  debt: "50",
};

type RenderPaymentProgressBarOptions = {
  caption?: "full" | "debtOnly" | "paidOfTotal";
  progress?: PaymentProgress;
};

function renderPaymentProgressBar({
  caption = "full",
  progress = baseProgress,
}: RenderPaymentProgressBarOptions = {}) {
  return render(<PaymentProgressBar caption={caption} progress={progress} />);
}
