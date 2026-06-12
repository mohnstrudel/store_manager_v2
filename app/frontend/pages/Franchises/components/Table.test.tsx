import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Table from "./Table";
import { makeFranchise } from "../test/factories";
import type { FranchiseRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Franchises/components/Table", () => {
  it("renders franchise rows with show and edit links", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "Pokemon" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute(
      "href",
      "/franchises/1"
    );
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/franchises/1/edit"
    );
  });

  it("navigates to the franchise page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const franchiseRow = screen
      .getByRole("cell", { name: "Pokemon" })
      .closest("tr");

    expect(franchiseRow).not.toBeNull();
    await user.click(franchiseRow!);

    expect(router.visit).toHaveBeenCalledWith("/franchises/1");
  });
});

function renderTable({
  franchises = [makeFranchise()],
}: { franchises?: FranchiseRecord[] } = {}) {
  return render(<Table franchises={franchises} />);
}
