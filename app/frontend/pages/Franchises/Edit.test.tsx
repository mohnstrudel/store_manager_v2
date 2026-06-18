import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeFranchise } from "./test/factories";


describe("Franchises/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
        render(<Edit franchise={makeFranchise()}/>);

    expect(screen.getByRole("heading", { name: "Edit Franchise" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Franchise Page/ })).toHaveAttribute(
      "href",
      "/franchises/1",
    );
    expect(screen.getByLabelText("Title")).toHaveValue("Pokemon");
    expect(screen.getByRole("button", { name: "Update Franchise" })).toBeInTheDocument();
  });
});


