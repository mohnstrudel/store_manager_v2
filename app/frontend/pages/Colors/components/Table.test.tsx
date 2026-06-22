import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import Table from "./Table";
import { makeColor } from "../test/factories";

describe("Colors/components/Table", () => {
  it("renders color rows with show and edit links", () => {
    render(<Table colors={[makeColor()]} />);

    expect(screen.getByRole("cell", { name: "Azure" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/colors/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/colors/1/edit");
  });

  it("navigates to the color page when a row is clicked", async () => {
    const user = userEvent.setup();
    render(<Table colors={[makeColor()]} />);
    const colorRow = screen.getByRole("cell", { name: "Azure" }).closest("tr");

    expect(colorRow).not.toBeNull();
    await user.click(colorRow!);

    expect(router.visit).toHaveBeenCalledWith("/colors/1");
  });
});
