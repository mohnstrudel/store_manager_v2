import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeSaleForm, makeSaleFormOptions } from "./test/factories";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

describe("Sales/Edit", () => {
  it("renders the edit heading, view link, and update button", () => {
    render(
      <Edit options={makeSaleFormOptions()} sale={makeSaleForm({ id: 10, path: "/sales/10" })} />,
    );

    expect(screen.getByRole("heading", { name: "Edit Sale" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Sale/ })).toHaveAttribute("href", "/sales/10");
    expect(screen.getByRole("button", { name: "Update Sale" })).toBeInTheDocument();
  });
});
