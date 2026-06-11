import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeFranchise } from "./test/factories";
import type { FranchiseRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Franchises/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

    expect(
      screen.getByRole("heading", { name: "Edit Franchise" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /View Franchise Page/ })
    ).toHaveAttribute("href", "/franchises/1");
    expect(screen.getByLabelText("Title")).toHaveValue("Pokemon");
    expect(
      screen.getByRole("button", { name: "Update Franchise" })
    ).toBeInTheDocument();
  });
});

function renderEdit({
  franchise = makeFranchise(),
}: { franchise?: FranchiseRecord } = {}) {
  return render(<Edit franchise={franchise} />);
}
