import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeSupplier } from "./test/factories";
import type { SupplierRecord } from "./types";

describe("Suppliers/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

    expect(screen.getByRole("heading", { name: "Edit Supplier" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Supplier Page/ })).toHaveAttribute(
      "href",
      "/suppliers/1",
    );
    expect(screen.getByLabelText("Title")).toHaveValue("GoodSmile");
    expect(screen.getByRole("button", { name: "Update Supplier" })).toBeInTheDocument();
  });
});

function renderEdit({ supplier = makeSupplier() }: { supplier?: SupplierRecord } = {}) {
  return render(<Edit supplier={supplier} />);
}
