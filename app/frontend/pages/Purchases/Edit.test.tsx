import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makePurchaseForm, makePurchaseFormOptions } from "./test/factories";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

describe("Purchases/Edit", () => {
  it("renders the edit heading, view link, and update button", () => {
    render(<Edit options={makePurchaseFormOptions()} purchase={makePurchaseForm({ id: 55, path: "/purchases/55" })} />);

    expect(screen.getByRole("heading", { name: "Edit Purchase" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Purchase Page/ })).toHaveAttribute(
      "href",
      "/purchases/55",
    );
    expect(screen.getByRole("button", { name: "Update Purchase" })).toBeInTheDocument();
  });
});
