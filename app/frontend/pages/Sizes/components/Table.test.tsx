import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Table from "./Table";
import { makeSize } from "../test/factories";
import type { SizeRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Sizes/components/Table", () => {
  it("renders size rows with show and edit links", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "1:6" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/sizes/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/sizes/1/edit");
  });

  it("navigates to the size page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const sizeRow = screen.getByRole("cell", { name: "1:6" }).closest("tr");

    expect(sizeRow).not.toBeNull();
    await user.click(sizeRow!);

    expect(router.visit).toHaveBeenCalledWith("/sizes/1");
  });
});

function renderTable({ sizes = [makeSize()] }: { sizes?: SizeRecord[] } = {}) {
  return render(<Table sizes={sizes} />);
}
