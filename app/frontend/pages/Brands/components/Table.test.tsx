import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import Table from "./Table";
import { makeBrand } from "../test/factories";

describe("Brands/components/Table", () => {
  it("renders brand rows with show and edit links", () => {
    render(<Table brands={[makeBrand()]} />);

    expect(screen.getByRole("cell", { name: "Moonbow" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/brands/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/brands/1/edit");
  });

  it("navigates to the brand page when a row is clicked", async () => {
    const user = userEvent.setup();
    render(<Table brands={[makeBrand()]} />);
    const brandRow = screen.getByRole("cell", { name: "Moonbow" }).closest("tr");

    expect(brandRow).not.toBeNull();
    await user.click(brandRow!);

    expect(router.visit).toHaveBeenCalledWith("/brands/1");
  });
});
