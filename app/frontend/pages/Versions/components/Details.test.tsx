import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Details from "./Details";
import { makeVersion } from "../test/factories";
import type { VersionRecord } from "../types";

describe("Versions/components/Details", () => {
  it("renders the version detail table", () => {
    renderDetails();

    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "Classic" })).toBeInTheDocument();
    expect(screen.getByText("19. May '26 16:18")).toBeInTheDocument();
    expect(screen.getByText("20. May '26 16:18")).toBeInTheDocument();
  });
});

function renderDetails({
  version = makeVersion(),
}: { version?: VersionRecord } = {}) {
  return render(<Details version={version} />);
}
