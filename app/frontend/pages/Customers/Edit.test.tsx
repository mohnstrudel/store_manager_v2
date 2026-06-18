import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeCustomer } from "./test/factories";
import type { CustomerRecord } from "./types";

describe("Customers/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

    expect(screen.getByRole("heading", { name: "Edit Customer" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Customer Page/ })).toHaveAttribute(
      "href",
      "/customers/1",
    );
    expect(screen.getByLabelText("First name")).toHaveValue("Dale");
    expect(screen.getByLabelText("Email")).toHaveValue("dale@fbi.gov");
    expect(screen.getByRole("button", { name: "Update Customer" })).toBeInTheDocument();
  });
});

function renderEdit({ customer = makeCustomer() }: { customer?: CustomerRecord } = {}) {
  return render(<Edit customer={customer} />);
}
