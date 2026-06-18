import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Show from "./Show";
import { makeSaleShow } from "./test/factories";

describe("Sales/Show", () => {
  it("renders the Shopify sale title and composed sections", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: "Sale HSCM#1746" })).toBeInTheDocument();
    expect(screen.getByText("Pikachu Figure")).toBeInTheDocument();
    expect(screen.getByText("Leave at the door")).toBeInTheDocument();
  });

  it("renders the WooCommerce sale title when the sale is only linked to Woo", () => {
    renderShow({
      shop_identifier: "WOO-1",
      shopify_id: "",
      shopify_name: "",
      woo_store_id: "WOO-1",
    });

    expect(screen.getByRole("heading", { name: "Sale WOO-1" })).toBeInTheDocument();
  });

  it("falls back to the local id in the title when the sale has no store identifiers", () => {
    renderShow({ shop_identifier: "", shopify_id: "", shopify_name: "", woo_store_id: "" });

    expect(screen.getByRole("heading", { name: "Sale 1" })).toBeInTheDocument();
  });
});

function renderShow(overrides: Partial<ReturnType<typeof makeSaleShow>> = {}) {
  return render(<Show sale={makeSaleShow(overrides)} />);
}
