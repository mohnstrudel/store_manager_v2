import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import ErrorNotice from "./ErrorNotice";

describe("ErrorNotice", () => {
  it("renders a full-width notice for client and server errors", () => {
    render(<ErrorNotice errors={{ title: "can't be blank" }} />);

    expect(screen.getByText("Fix errors and try again").closest("article")).toHaveClass("w-full");
  });

  it("lists top-level errors by a readable name and leaves nested field errors to their fields", () => {
    render(
      <ErrorNotice
        errors={{ variants: "is invalid", "variants.0.sku": "has already been taken" }}
      />,
    );

    expect(screen.getAllByRole("listitem").map((item) => item.textContent)).toEqual([
      "Variants: is invalid",
    ]);
  });
});
