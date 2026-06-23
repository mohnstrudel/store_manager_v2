import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeCustomer } from "./test/factories";

describe("Customers/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    render(<Edit customer={makeCustomer()} />);

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
