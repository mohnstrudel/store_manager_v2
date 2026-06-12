import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeBrand } from "./test/factories";
import type { BrandRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Brands/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

    expect(screen.getByRole("heading", { name: "Edit Brand" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Brand Page/ })).toHaveAttribute(
      "href",
      "/brands/1",
    );
    expect(screen.getByLabelText("Title")).toHaveValue("Moonbow");
    expect(screen.getByRole("button", { name: "Update Brand" })).toBeInTheDocument();
  });
});

function renderEdit({ brand = makeBrand() }: { brand?: BrandRecord } = {}) {
  return render(<Edit brand={brand} />);
}
