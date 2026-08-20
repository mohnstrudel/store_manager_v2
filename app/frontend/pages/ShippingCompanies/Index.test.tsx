import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";
import { makeShippingCompany } from "./test/factories";

describe("ShippingCompanies/Index", () => {
  it("renders the heading, add link, and table row", () => {
    render(<Index shippingCompanies={[makeShippingCompany()]} />);

    expect(screen.getByRole("heading", { name: "Shipping Companies" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/shipping_companies/new",
    );
    expect(screen.getByRole("cell", { name: "DHL" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute(
      "href",
      "/shipping_companies/1",
    );
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/shipping_companies/1/edit",
    );
  });
});
