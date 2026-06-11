import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Table from "./Table";
import { makeColor } from "../test/factories";
import type { ColorRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Colors/components/Table", () => {
  it("renders color rows with show and edit links", () => {
    renderTable();

    expect(screen.getByRole("cell", { name: "Azure" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/colors/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/colors/1/edit");
  });

  it("navigates to the color page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const colorRow = screen.getByRole("cell", { name: "Azure" }).closest("tr");

    expect(colorRow).not.toBeNull();
    await user.click(colorRow!);

    expect(router.visit).toHaveBeenCalledWith("/colors/1");
  });
});

function renderTable({ colors = [makeColor()] }: { colors?: ColorRecord[] } = {}) {
  return render(<Table colors={colors} />);
}
