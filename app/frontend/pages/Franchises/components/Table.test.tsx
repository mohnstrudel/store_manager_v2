import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import Table from "./Table";
import { makeFranchise } from "../test/factories";

describe("Franchises/components/Table", () => {
  it("renders franchise rows with show and edit links", () => {
    render(<Table franchises={[makeFranchise()]} />);

    expect(screen.getByRole("cell", { name: "Pokemon" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/franchises/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/franchises/1/edit",
    );
  });

  it("navigates to the franchise page when a row is clicked", async () => {
    const user = userEvent.setup();
    render(<Table franchises={[makeFranchise()]} />);
    const franchiseRow = screen.getByRole("cell", { name: "Pokemon" }).closest("tr");

    expect(franchiseRow).not.toBeNull();
    await user.click(franchiseRow!);

    expect(router.visit).toHaveBeenCalledWith("/franchises/1");
  });
});
