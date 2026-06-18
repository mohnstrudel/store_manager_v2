import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makeSize } from "./test/factories";


describe("Sizes/Index", () => {
  it("renders the sizes table and new-record link", () => {
        render(<Index sizes={[makeSize()]}/>);

    expect(screen.getByRole("heading", { name: "Sizes" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/sizes/new",
    );
    expect(screen.getByRole("cell", { name: "1:6" })).toBeInTheDocument();
  });
});


