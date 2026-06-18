import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { router } from "@inertiajs/react";
import { describe, expect, it } from "vitest";
import IndexTable from "./IndexTable";
import { makeUser } from "../test/factories";


describe("Users/components/IndexTable", () => {
  it("renders user rows with an edit link", () => {
        render(<IndexTable users={[makeUser()]}/>);

    expect(screen.getByRole("cell", { name: "ash@example.com" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/users/1/edit");
  });

  it("navigates to the user page when a row is clicked", async () => {
    const user = userEvent.setup();
        render(<IndexTable users={[makeUser()]}/>);
    const userRow = screen.getByRole("cell", { name: "ash@example.com" }).closest("tr");

    expect(userRow).not.toBeNull();
    await user.click(userRow!);

    expect(router.visit).toHaveBeenCalledWith("/users/1");
  });
});


