import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it, vi } from "vitest";
import IndexTable from "./IndexTable";
import { makeUser } from "../test/factories";
import type { UserRecord } from "./IndexTable";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Users/components/IndexTable", () => {
  it("renders user rows with an edit link", () => {
    renderTable();

    expect(
      screen.getByRole("cell", { name: "ash@example.com" })
    ).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/users/1/edit"
    );
  });

  it("navigates to the user page when a row is clicked", async () => {
    const user = userEvent.setup();
    renderTable();
    const userRow = screen
      .getByRole("cell", { name: "ash@example.com" })
      .closest("tr");

    expect(userRow).not.toBeNull();
    await user.click(userRow!);

    expect(router.visit).toHaveBeenCalledWith("/users/1");
  });
});

function renderTable({ users = [makeUser()] }: { users?: UserRecord[] } = {}) {
  return render(<IndexTable users={users} />);
}
