import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeSupplier } from "./test/factories";

describe("Suppliers/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    render(<Edit supplier={makeSupplier()} />);

    expect(screen.getByRole("heading", { name: "Edit Supplier" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Supplier Page/ })).toHaveAttribute(
      "href",
      "/suppliers/1",
    );
    expect(screen.getByLabelText("Title")).toHaveValue("GoodSmile");
    expect(screen.getByRole("button", { name: "Update Supplier" })).toBeInTheDocument();
  });
});
