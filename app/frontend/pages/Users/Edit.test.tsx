import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import Edit from "./Edit";
import { makeUserForm } from "./test/factories";
import type { UserFormValues } from "./components/Form";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

describe("Users/Edit", () => {
  it("renders the edit heading, view link, and populated form", () => {
    renderEdit();

    expect(
      screen.getByRole("heading", { name: "Edit User" })
    ).toBeInTheDocument();
    expect(
      screen.getByRole("link", { name: /View User Page/ })
    ).toHaveAttribute("href", "/users/1");
    expect(screen.getByLabelText("Email")).toHaveValue("ash@example.com");
    expect(screen.getByLabelText("First Name")).toHaveValue("Ash");
    expect(screen.getByLabelText("Last Name")).toHaveValue("Ketchum");
    expect(screen.getByRole("combobox", { name: "Role" })).toBeInTheDocument();
    expect(
      screen.getByRole("button", { name: "Update User" })
    ).toBeInTheDocument();
  });
});

function renderEdit({
  is_admin = false,
  role_options = [["Manager", "manager"]],
  user = makeUserForm(),
}: {
  is_admin?: boolean;
  role_options?: [string, string][];
  user?: UserFormValues;
} = {}) {
  return render(
    <Edit is_admin={is_admin} role_options={role_options} user={user} />
  );
}
