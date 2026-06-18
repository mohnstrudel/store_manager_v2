import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import New from "./New";
import { makeShippingCompany } from "./test/factories";
import type { ShippingCompanyRecord } from "./types";

describe("ShippingCompanies/New", () => {
  it("renders the form", () => {
    renderNew();

    expect(screen.getByRole("heading", { name: "New Shipping Company" })).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toBeInTheDocument();
    expect(screen.getByLabelText("Tracking URL")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Shipping Company" })).toBeInTheDocument();
  });

  it("renders field validation errors", () => {
    mockPageProps({ errors: { tracking_url: "can't be blank" } });

    renderNew();

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getAllByText("can't be blank").length).toBeGreaterThan(0);
  });
});

function renderNew({
  shippingCompany = makeShippingCompany({
    id: null,
    name: "",
    tracking_url: null,
    created_at: null,
    updated_at: null,
  }),
}: {
  shippingCompany?: ShippingCompanyRecord;
} = {}) {
  return render(<New shippingCompany={shippingCompany} />);
}
