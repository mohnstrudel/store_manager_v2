import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import routes from "@/utils/routes";
import New from "./New";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

vi.mock("@/components/flash-messages/FlashMessages", () => ({
  default: () => <div data-testid="flash-messages" />,
}));

describe("Signups/New", () => {
  afterEach(() => {
    document.body.className = "";
  });

  it("renders the sign-up heading, fields, submit action, and auth links", () => {
    render(<New email_address="laura@blacklodge.io" />);

    expect(screen.getByRole("heading", { name: "Create new account" })).toBeInTheDocument();
    expect(screen.getByRole("textbox", { name: "Email address" })).toHaveValue(
      "laura@blacklodge.io",
    );
    expect(screen.getByLabelText("Email address")).toHaveAttribute("name", "user[email_address]");
    expect(screen.getByLabelText("Password")).toHaveAttribute("name", "user[password]");
    expect(screen.getByRole("button", { name: "Sign up" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Already have an account?" })).toHaveAttribute(
      "href",
      routes.sessions.new.path(),
    );
    expect(screen.getByRole("link", { name: "Forgot password?" })).toHaveAttribute(
      "href",
      routes.passwords.new.path(),
    );

    const form = screen.getByRole("button", { name: "Sign up" }).closest("form");
    expect(form).toHaveAttribute("action", routes.signups.create.path());
    expect(form).toHaveAttribute("data-method", "post");
  });

  it("renders server-side email and password errors", () => {
    mockPageProps({
      errors: {
        email_address: "Email address can't be blank",
        password: "Password is too short",
      },
    });

    render(<New email_address={null} />);

    expect(screen.getByText("Email address can't be blank")).toBeInTheDocument();
    expect(screen.getByText("Password is too short")).toBeInTheDocument();
  });

  it("wraps the page in the auth layout", () => {
    render(<>{New.layout?.(<div>Signup layout content</div>)}</>);

    expect(document.body).toHaveClass("wbg");
    expect(screen.getByTestId("flash-messages")).toBeInTheDocument();
    expect(screen.getByText("Signup layout content")).toBeInTheDocument();
  });
});
