import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import Index from "./Index";
import { makeUser } from "./test/factories";

describe("Users/Index", () => {
  it("renders the user heading and table row", () => {
    render(<Index users={[makeUser()]} />);

    expect(screen.getByRole("heading", { name: "Users" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "ash@example.com" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/users/1/edit");
  });
});
