import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Details from "./Details";
import { makeFranchise } from "../test/factories";

describe("Franchises/components/Details", () => {
  it("renders the franchise detail table", () => {
    render(<Details franchise={makeFranchise()} />);

    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "Pokemon" })).toBeInTheDocument();
    expect(screen.getAllByText("19. May '26 16:18")).toHaveLength(2);
  });
});
