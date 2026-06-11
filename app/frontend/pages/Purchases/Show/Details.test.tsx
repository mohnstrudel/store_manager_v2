import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Details from "./Details";
import { makePurchaseShow } from "../test/factories";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Purchases/Show/Details", () => {
  it("renders the purchase summary and supplier link", () => {
    render(<Details purchase={makePurchaseShow({ paid: "" })} />);

    expect(screen.getByRole("link", { name: "Acme Imports" })).toHaveAttribute(
      "href",
      "/suppliers/1",
    );
    expect(screen.getByRole("img", { name: "Pikachu Figure" })).toBeInTheDocument();
    expect(screen.getByText("0")).toBeInTheDocument();
    expect(screen.getByText("-160.00")).toBeInTheDocument();
    expect(screen.getByText("PO-55")).toBeInTheDocument();
    expect(screen.getByText("20 May 2026")).toBeInTheDocument();
  });

  it("omits the image when the purchase has no product image", () => {
    render(<Details purchase={makePurchaseShow({ product_image_url: null })} />);

    expect(screen.queryByRole("img", { name: "Pikachu Figure" })).not.toBeInTheDocument();
  });
});
