import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeBrand } from "./test/factories";


describe("Brands/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
        render(<Edit brand={makeBrand()}/>);

    expect(screen.getByRole("heading", { name: "Edit Brand" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Brand Page/ })).toHaveAttribute(
      "href",
      "/brands/1",
    );
    expect(screen.getByLabelText("Title")).toHaveValue("Moonbow");
    expect(screen.getByRole("button", { name: "Update Brand" })).toBeInTheDocument();
  });
});


