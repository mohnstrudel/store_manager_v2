import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import Table from "./Table";
import { makeShippingCompany } from "../test/factories";
import type { ShippingCompanyRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("ShippingCompanies/components/Table", () => {
  it("renders shipping company rows with show and edit links", () => {
    renderTable();

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

  it("renders the tracking URL as a link", () => {
    renderTable();

    expect(screen.getByRole("link", { name: "https://dhl.com/track" })).toHaveAttribute(
      "href",
      "https://dhl.com/track",
    );
  });

  it("shows an empty cell when tracking URL is absent", () => {
    renderTable({
      shippingCompanies: [makeShippingCompany({ tracking_url: null })],
    });

    expect(screen.queryByRole("link", { name: /dhl\.com/ })).not.toBeInTheDocument();
  });

  it("navigates to the shipping company page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const row = screen.getByRole("cell", { name: "DHL" }).closest("tr");

    expect(row).not.toBeNull();
    await user.click(row!);

    expect(router.visit).toHaveBeenCalledWith("/shipping_companies/1");
  });
});

function renderTable({
  shippingCompanies = [makeShippingCompany()],
}: { shippingCompanies?: ShippingCompanyRecord[] } = {}) {
  return render(<Table shippingCompanies={shippingCompanies} />);
}
