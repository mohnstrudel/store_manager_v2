import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Index from "./Index";
import { makeVersion } from "./test/factories";
import type { VersionRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Versions/Index", () => {
  it("renders the version heading, add link, and table row", () => {
    renderIndex();

    expect(
      screen.getByRole("heading", { name: "Versions" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /Add New Record/ })
    ).toHaveAttribute("href", "/versions/new");
    expect(screen.getByRole("cell", { name: "Classic" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute(
      "href",
      "/versions/1"
    );
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/versions/1/edit"
    );
  });
});

function renderIndex({
  versions = [makeVersion()],
}: { versions?: VersionRecord[] } = {}) {
  return render(<Index versions={versions} />);
}
