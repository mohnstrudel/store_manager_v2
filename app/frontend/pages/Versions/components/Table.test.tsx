import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makeVersion } from "../test/factories";
import Table from "./Table";

describe("Versions/components/Table", () => {
  it("renders version rows with show and edit links", () => {
    render(<Table versions={[makeVersion()]} />);

    expect(screen.getByRole("cell", { name: "Classic" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/versions/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/versions/1/edit");
  });

  it("navigates to the version page when a row is clicked", async () => {
    const user = userEvent.setup();
    render(<Table versions={[makeVersion()]} />);
    const versionRow = screen.getByRole("cell", { name: "Classic" }).closest("tr");

    expect(versionRow).not.toBeNull();
    await user.click(versionRow!);

    expect(router.visit).toHaveBeenCalledWith("/versions/1");
  });
});
