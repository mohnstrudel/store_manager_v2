import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeVersion } from "./test/factories";
import type { VersionRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Versions/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

    expect(
      screen.getByRole("heading", { name: "Edit Version" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /View Version Page/ })
    ).toHaveAttribute("href", "/versions/1");
    expect(screen.getByLabelText("Value")).toHaveValue("Classic");
    expect(
      screen.getByRole("button", { name: "Update Version" })
    ).toBeInTheDocument();
  });
});

function renderEdit({
  version = makeVersion(),
}: { version?: VersionRecord } = {}) {
  return render(<Edit version={version} />);
}
