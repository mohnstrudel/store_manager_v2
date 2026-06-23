import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import routes from "@/utils/routes";
import New from "./New";

describe("Passwords/New", () => {
  it("renders the heading and submit button", () => {
    render(<New />);

    expect(screen.getByRole("heading", { name: "Forgot your password?" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Email reset instructions" })).toBeInTheDocument();
  });

  it("renders the email address field", () => {
    render(<New />);

    expect(screen.getByRole("textbox", { name: "Email address" })).toBeInTheDocument();
  });

  it("prefills the email address when provided", () => {
    render(<New email_address="user@example.com" />);

    expect(screen.getByRole("textbox", { name: "Email address" })).toHaveValue("user@example.com");
  });

  it("posts to the passwords create route", () => {
    render(<New />);

    const form = screen.getByRole("button", { name: "Email reset instructions" }).closest("form");
    expect(form).toHaveAttribute("action", routes.passwords.create.path());
  });

  it("links to account signup and sign in", () => {
    render(<New />);

    expect(screen.getByRole("link", { name: "Create new account" })).toHaveAttribute(
      "href",
      routes.signups.new.path(),
    );
    expect(screen.getByRole("link", { name: "Already have an account?" })).toHaveAttribute(
      "href",
      routes.sessions.new.path(),
    );
  });
});
