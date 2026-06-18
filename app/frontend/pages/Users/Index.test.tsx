import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makeUser } from "./test/factories";
import type { UserRecord } from "./components/IndexTable";

describe("Users/Index", () => {
  it("renders the user heading and table row", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Users" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "ash@example.com" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/users/1/edit");
  });
});

function renderIndex({ users = [makeUser()] }: { users?: UserRecord[] } = {}) {
  return render(<Index users={users} />);
}
