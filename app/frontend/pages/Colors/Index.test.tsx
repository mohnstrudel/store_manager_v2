import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makeColor } from "./test/factories";


describe("Colors/Index", () => {
  it("renders the colors table and new-record link", () => {
        render(<Index colors={[makeColor()]}/>);

    expect(screen.getByRole("heading", { name: "Colors" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/colors/new",
    );
    expect(screen.getByRole("cell", { name: "Azure" })).toBeInTheDocument();
  });
});


