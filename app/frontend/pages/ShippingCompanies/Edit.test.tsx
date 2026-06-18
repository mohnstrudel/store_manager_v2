import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Edit from "./Edit";
import { makeShippingCompany } from "./test/factories";


describe("ShippingCompanies/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
        render(<Edit shippingCompany={makeShippingCompany()}/>);

    expect(screen.getByRole("heading", { name: "Edit Shipping Company" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Shipping Company Page/ })).toHaveAttribute(
      "href",
      "/shipping_companies/1",
    );
    expect(screen.getByLabelText("Name")).toHaveValue("DHL");
    expect(screen.getByLabelText("Tracking URL")).toHaveValue("https://dhl.com/track");
    expect(screen.getByRole("button", { name: "Update Shipping Company" })).toBeInTheDocument();
  });
});


