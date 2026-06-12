import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { router } from "@inertiajs/react";
import PurchasesSection from "./PurchasesSection";
import { makePurchase } from "../test/factories";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Products/Show/PurchasesSection", () => {
  it("renders nothing without purchases", () => {
    const { container } = render(<PurchasesSection purchases={[]} />);

    expect(container).toBeEmptyDOMElement();
  });

  it("totals purchase amounts in the header", () => {
    render(
      <PurchasesSection
        purchases={[makePurchase({ id: 1, amount: 2 }), makePurchase({ id: 2, amount: 3 })]}
      />,
    );

    expect(screen.getByRole("heading", { name: /5/ })).toBeInTheDocument();
  });

  it("renders supplier, reference, price, amount, and time ago for each purchase", () => {
    render(<PurchasesSection purchases={[makePurchase()]} />);

    expect(screen.getByRole("cell", { name: "GoodSmile" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "GS-1001" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "12.50" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "2 days ago" })).toBeInTheDocument();
  });

  it("joins warehouse names with commas", () => {
    render(
      <PurchasesSection
        purchases={[
          makePurchase({
            warehouses: [
              { id: 1, name: "Tokyo" },
              { id: 2, name: "Osaka" },
            ],
          }),
        ]}
      />,
    );

    expect(screen.getByRole("cell", { name: "Tokyo, Osaka" })).toBeInTheDocument();
  });

  it("visits the purchase when the row is clicked", async () => {
    const user = userEvent.setup();
    render(<PurchasesSection purchases={[makePurchase()]} />);

    await user.click(screen.getByRole("row", { name: /GoodSmile/ }));

    expect(router.visit).toHaveBeenCalledWith("/purchases/1");
  });
});
