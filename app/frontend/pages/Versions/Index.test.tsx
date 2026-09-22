import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";
import { makeVersion } from "./test/factories";

describe("Versions/Index", () => {
  it("renders the version heading, add link, and table row", () => {
    render(<Index versions={[makeVersion()]} />);

    expect(screen.getByRole("heading", { name: "Versions" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/versions/new",
    );
    expect(screen.getByRole("cell", { name: "Classic" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Show/ })).toHaveAttribute("href", "/versions/1");
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/versions/1/edit");
  });
});
