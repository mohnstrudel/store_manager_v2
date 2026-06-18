import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import New from "./New";
import { makePurchaseForm, makePurchaseFormOptions } from "./test/factories";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

describe("Purchases/New", () => {
  it("renders the new heading and create button", () => {
    render(<New options={makePurchaseFormOptions()} purchase={makePurchaseForm()} />);

    expect(screen.getByRole("heading", { name: "New Purchase" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Create Purchase" })).toBeInTheDocument();
  });
});
