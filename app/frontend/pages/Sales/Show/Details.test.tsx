import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import Details from "./Details";
import { makeSaleShow } from "../test/factories";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Sales/Show/Details", () => {
  it("renders the customer, note, totals, and store identifiers", () => {
    render(<Details sale={makeSaleShow()} />);

    expect(screen.getByText("Processing")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Dale Cooper" })).toHaveAttribute(
      "href",
      "/customers/2",
    );
    expect(screen.getByText("Leave at the door")).toBeInTheDocument();
    expect(screen.getByText("1060")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "7383283466569" })).toHaveAttribute(
      "href",
      "https://admin.shopify.com/store/68d8f5-af/orders/7383283466569",
    );
  });

  it("switches to the billing tab and renders the billing address", async () => {
    const user = userEvent.setup();
    render(<Details sale={makeSaleShow()} />);

    await user.click(screen.getByRole("button", { name: /Billing/ }));

    expect(screen.getByText("Billing address differs from shipping.")).toBeInTheDocument();
    expect(screen.getByText("456 Side St")).toBeInTheDocument();
    expect(screen.getByText("Paris")).toBeInTheDocument();
  });

  it("hides empty customer and address details", () => {
    render(
      <Details
        sale={makeSaleShow({
          billing_address: null,
          customer: makeSaleShow().customer,
          note: "",
          shipping_address: null,
        })}
      />,
    );

    expect(screen.queryByText("Leave at the door")).not.toBeInTheDocument();
    expect(screen.queryByText("Address 1")).not.toBeInTheDocument();
  });
});
