import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeShippingCompany } from "./test/factories";
import type { ShippingCompanyRecord } from "./types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("ShippingCompanies/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

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

function renderEdit({
  shippingCompany = makeShippingCompany(),
}: { shippingCompany?: ShippingCompanyRecord } = {}) {
  return render(<Edit shippingCompany={shippingCompany} />);
}
