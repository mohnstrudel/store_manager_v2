import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import routes from "@/utils/routes";
import Edit from "./Edit";

describe("Passwords/Edit", () => {
  it("renders the heading and submit button", () => {
    render(<Edit token="abc123" />);

    expect(screen.getByRole("heading", { name: "Reset your password" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Save new password" })).toBeInTheDocument();
  });

  it("renders the new password and confirmation fields", () => {
    render(<Edit token="abc123" />);

    expect(screen.getByLabelText("New password")).toBeInTheDocument();
    expect(screen.getByLabelText("Confirm new password")).toBeInTheDocument();
  });

  it("submits to the passwords update route with the token", () => {
    render(<Edit token="abc123" />);

    const form = screen.getByRole("button", { name: "Save new password" }).closest("form");
    expect(form).toHaveAttribute("action", routes.passwords.update.path({ token: "abc123" }));
  });
});
