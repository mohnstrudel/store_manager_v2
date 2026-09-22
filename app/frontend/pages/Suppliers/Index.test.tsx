import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";
import { makeSupplier } from "./test/factories";

describe("Suppliers/Index", () => {
  it("renders the supplier heading, add link, and table row", () => {
    render(<Index suppliers={[makeSupplier()]} />);

    expect(screen.getByRole("heading", { name: "Suppliers" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/suppliers/new",
    );
    expect(screen.getByRole("cell", { name: "GoodSmile" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/suppliers/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/suppliers/1/edit");
  });
});
