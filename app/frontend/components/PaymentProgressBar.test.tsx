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

  describe("when onlyDebt is false (default)", () => {
    it("shows paid, price, and debt when progress is incomplete", () => {
      renderPaymentProgressBar({
        progress: { progress: 25, paid: "$50", price: "$200", debt: "$150" },
      });

      expect(screen.getByText("$50")).toBeInTheDocument();
      expect(screen.getByText("$200")).toBeInTheDocument();
      expect(screen.getByText("$150")).toBeInTheDocument();
    });

    it("hides the detail row when fully paid", () => {
      renderPaymentProgressBar({
        progress: { progress: 100, paid: "$200", price: "$200", debt: "$0" },
      });

      expect(screen.queryByText("$200")).not.toBeInTheDocument();
    });

    it("shows 'n/p' when paid is empty", () => {
      renderPaymentProgressBar({
        progress: { progress: 50, paid: "", price: "$100", debt: "$50" },
      });

      expect(screen.getByText("n/p")).toBeInTheDocument();
    });
  });

  describe("when onlyDebt is true", () => {
    it("shows only the debt amount when payment is incomplete", () => {
      renderPaymentProgressBar({
        onlyDebt: true,
        progress: { progress: 25, paid: "50.00", price: "200.00", debt: "150.00" },
      });

      expect(screen.getByText("$150.00 debt")).toBeInTheDocument();
      expect(screen.queryByText("50.00")).not.toBeInTheDocument();
    });

    it("hides the debt section when fully paid", () => {
      renderPaymentProgressBar({
        onlyDebt: true,
        progress: { progress: 100, paid: "$200", price: "$200", debt: "$0" },
      });

      expect(screen.queryByText(/debt/)).not.toBeInTheDocument();
    });
  });
});

const baseProgress: PaymentProgress = {
  progress: 50,
  paid: "$50",
  price: "$100",
  debt: "$50",
};

type RenderPaymentProgressBarOptions = {
  onlyDebt?: boolean;
  progress?: PaymentProgress;
};

function renderPaymentProgressBar({
  onlyDebt = false,
  progress = baseProgress,
}: RenderPaymentProgressBarOptions = {}) {
  return render(<PaymentProgressBar onlyDebt={onlyDebt} progress={progress} />);
}
