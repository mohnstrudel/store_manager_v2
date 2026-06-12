import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Details from "./Details";
import { makeShippingCompany } from "../test/factories";
import type { ShippingCompanyRecord } from "../types";

describe("ShippingCompanies/components/Details", () => {
  it("renders the shipping company detail table", () => {
    renderDetails();

    expect(screen.getByRole("cell", { name: "1" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "DHL" })).toBeInTheDocument();
    expect(screen.getByText("19. May '26 16:18")).toBeInTheDocument();
    expect(screen.getByText("20. May '26 16:18")).toBeInTheDocument();
  });

  it("renders the tracking URL as a link", () => {
    renderDetails();

    expect(screen.getByRole("link", { name: "https://dhl.com/track" })).toHaveAttribute(
      "href",
      "https://dhl.com/track",
    );
  });

  it("shows an empty cell when tracking URL is absent", () => {
    renderDetails({
      shippingCompany: makeShippingCompany({ tracking_url: null }),
    });

    expect(screen.queryByRole("link", { name: /dhl\.com/ })).not.toBeInTheDocument();
  });
});

function renderDetails({
  shippingCompany = makeShippingCompany(),
}: { shippingCompany?: ShippingCompanyRecord } = {}) {
  return render(<Details shippingCompany={shippingCompany} />);
}
