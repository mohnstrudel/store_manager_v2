import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Details from "./Details";
import { makeFranchise } from "../test/factories";
import type { FranchiseRecord } from "../types";

describe("Franchises/components/Details", () => {
  it("renders the franchise detail table", () => {
    renderDetails();

    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "Pokemon" })).toBeInTheDocument();
    expect(screen.getAllByText("19. May '26 16:18")).toHaveLength(2);
  });
});

function renderDetails({
  franchise = makeFranchise(),
}: { franchise?: FranchiseRecord } = {}) {
  return render(<Details franchise={franchise} />);
}
