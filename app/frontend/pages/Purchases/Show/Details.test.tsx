import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { makePurchaseShow } from "../test/factories";
import Details from "./Details";

describe("Purchases/Show/Details", () => {
  it("renders the purchase summary and supplier link", () => {
    render(<Details purchase={makePurchaseShow()} />);

    expect(screen.getByRole("link", { name: "Acme Imports" })).toHaveAttribute(
      "href",
      "/suppliers/1",
    );
    expect(screen.getByRole("img", { name: "Pikachu Figure" })).toBeInTheDocument();
    expect(screen.getByText("50.00")).toBeInTheDocument();
    expect(screen.getByText("-160.00")).toBeInTheDocument();
    expect(screen.getByText("PO-55")).toBeInTheDocument();
    expect(screen.getByText("20 May 2026")).toBeInTheDocument();
    expect(screen.getByText("Direct expenses")).toBeInTheDocument();
  });

  it("hides the paid row when nothing has been paid yet", () => {
    render(<Details purchase={makePurchaseShow({ paid: "" })} />);

    expect(screen.queryByText("Paid")).not.toBeInTheDocument();
  });

  it("hides the debt row when there is no debt", () => {
    render(<Details purchase={makePurchaseShow({ debt: "" })} />);

    expect(screen.queryByText("Supplier debt")).not.toBeInTheDocument();
  });

  it("hides shipping and direct expenses when there are none", () => {
    render(<Details purchase={makePurchaseShow({ shipping_total: "", expenses_total: "" })} />);

    expect(screen.queryByText("Shipping")).not.toBeInTheDocument();
    expect(screen.queryByText("Direct expenses")).not.toBeInTheDocument();
  });

  it("omits the image when the purchase has no product image", () => {
    render(<Details purchase={makePurchaseShow({ product_image_url: null })} />);

    expect(screen.queryByRole("img", { name: "Pikachu Figure" })).not.toBeInTheDocument();
  });
});
