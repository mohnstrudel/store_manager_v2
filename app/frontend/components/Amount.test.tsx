import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Amount from "./Amount";

describe("Amount", () => {
  it("renders nothing for missing values", () => {
    const { container } = render(<Amount value={null} />);

    expect(container).toHaveTextContent("");
  });

  it("renders positive amounts in default ink", () => {
    render(<Amount value="1 060" />);

    const amount = screen.getByText("1 060");

    expect(amount).not.toHaveAttribute("data-tone");
  });

  it("renders negative amounts with a typographic minus and negative tone", () => {
    render(<Amount value="-96" />);

    const amount = screen.getByText("−96");

    expect(amount).toHaveAttribute("data-tone", "negative");
  });

  describe("when the sign is emphasized", () => {
    it("marks non-negative amounts with positive tone", () => {
      render(<Amount emphasizeSign value="150" />);

      expect(screen.getByText("150")).toHaveAttribute("data-tone", "positive");
    });

    it("keeps negative amounts negative", () => {
      render(<Amount emphasizeSign value="-50" />);

      expect(screen.getByText("−50")).toHaveAttribute("data-tone", "negative");
    });
  });
});
