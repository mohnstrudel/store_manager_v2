import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makeSize } from "../test/factories";
import Table from "./Table";

describe("Sizes/components/Table", () => {
  it("renders size rows with show and edit links", () => {
    render(<Table sizes={[makeSize()]} />);

    expect(screen.getByRole("cell", { name: "1:6" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/sizes/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/sizes/1/edit");
  });

  it("navigates to the size page when a row is clicked", async () => {
    const user = userEvent.setup();
    render(<Table sizes={[makeSize()]} />);
    const sizeRow = screen.getByRole("cell", { name: "1:6" }).closest("tr");

    expect(sizeRow).not.toBeNull();
    await user.click(sizeRow!);

    expect(router.visit).toHaveBeenCalledWith("/sizes/1");
  });
});
