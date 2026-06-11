import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeColor } from "./test/factories";
import type { ColorRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Colors/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

    expect(screen.getByRole("heading", { name: "Edit Color" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Color Page/ })).toHaveAttribute(
      "href",
      "/colors/1",
    );
    expect(screen.getByLabelText("Value")).toHaveValue("Azure");
    expect(screen.getByRole("button", { name: "Update Color" })).toBeInTheDocument();
  });
});

function renderEdit({ color = makeColor() }: { color?: ColorRecord } = {}) {
  return render(<Edit color={color} />);
}
