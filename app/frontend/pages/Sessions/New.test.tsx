import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import routes from "@/utils/routes";
import New from "./New";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

vi.mock("@/components/flash-messages/FlashMessages", () => ({
  default: () => <div data-testid="flash-messages" />,
}));

describe("Sessions/New", () => {
  afterEach(() => {
    document.body.className = "";
  });

  it("renders the sign-in heading, fields, submit action, and auth links", () => {
    render(<New email_address="dale@fbi.gov" />);

    expect(screen.getByRole("heading", { name: "Sign in with your email" })).toBeInTheDocument();
    expect(screen.getByRole("textbox", { name: "Email address" })).toHaveValue("dale@fbi.gov");
    expect(screen.getByLabelText("Password")).toHaveAttribute("name", "password");
    expect(screen.getByRole("button", { name: "Sign in" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Create new account" })).toHaveAttribute(
      "href",
      routes.signups.new.path(),
    );
    expect(screen.getByRole("link", { name: "Forgot password?" })).toHaveAttribute(
      "href",
      routes.passwords.new.path(),
    );

    const form = screen.getByRole("button", { name: "Sign in" }).closest("form");
    expect(form).toHaveAttribute("action", routes.sessions.create.path());
    expect(form).toHaveAttribute("data-method", "post");
  });

  it("renders server-side email and password errors", () => {
    mockPageProps({
      errors: {
        email_address: "Email address is invalid",
        password: "Password is incorrect",
      },
    });

    render(<New email_address={null} />);

    expect(screen.getByText("Email address is invalid")).toBeInTheDocument();
    expect(screen.getByText("Password is incorrect")).toBeInTheDocument();
  });

  it("wraps the page in the auth layout", () => {
    render(<>{New.layout?.(<div>Session layout content</div>)}</>);

    expect(document.body).toHaveClass("wbg");
    expect(screen.getByTestId("flash-messages")).toBeInTheDocument();
    expect(screen.getByText("Session layout content")).toBeInTheDocument();
  });
});
