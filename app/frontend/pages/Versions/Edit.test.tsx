import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Edit from "./Edit";
import { makeVersion } from "./test/factories";

describe("Versions/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    render(<Edit version={makeVersion()} />);

    expect(screen.getByRole("heading", { name: "Edit Version" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Version Page/ })).toHaveAttribute(
      "href",
      "/versions/1",
    );
    expect(screen.getByLabelText("Value")).toHaveValue("Classic");
    expect(screen.getByRole("button", { name: "Update Version" })).toBeInTheDocument();
  });
});
