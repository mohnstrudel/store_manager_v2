import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";
import { makeVersion } from "./test/factories";
import type { VersionRecord } from "./types";

describe("Versions/New", () => {
  it("renders the form", () => {
    renderNew();

    expect(screen.getByRole("heading", { name: "New Version" })).toBeInTheDocument();
    expect(screen.getByLabelText("Value")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Version" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { value: "can't be blank" } });

    renderNew();

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});

function renderNew({
  version = makeVersion({
    id: null,
    value: "",
    created_at: null,
    updated_at: null,
  }),
}: {
  version?: VersionRecord;
} = {}) {
  return render(<New version={version} />);
}
