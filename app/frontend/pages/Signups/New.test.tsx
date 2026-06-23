import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import routes from "@/utils/routes";
import New from "./New";

vi.mock("@/components/flash-messages/FlashMessages", () => ({
  default: () => <div data-testid="flash-messages" />,
}));

describe("Signups/New", () => {
  afterEach(() => {
    document.body.className = "";
  });

  describe("form shell", () => {
    it("renders the sign-up heading and submit button", () => {
      renderPage();

      expect(screen.getByRole("heading", { name: "Create new account" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Sign up" })).toBeInTheDocument();
    });

    it("prefills the email field and renders signup field names", () => {
      renderPage();

      expect(screen.getByRole("textbox", { name: "Email address" })).toHaveValue(
        "laura@blacklodge.io",
      );
      expect(screen.getByLabelText("Email address")).toHaveAttribute("name", "user[email_address]");
      expect(screen.getByLabelText("Password")).toHaveAttribute("name", "user[password]");
    });

    it("posts to the signup create route", () => {
      renderPage();

      const form = screen.getByRole("button", { name: "Sign up" }).closest("form");

      expect(form).toHaveAttribute("action", routes.signups.create.path());
      expect(form).toHaveAttribute("data-method", "post");
    });
  });

  describe("navigation links", () => {
    it("links to the sign-in page", () => {
      renderPage();

      expect(screen.getByRole("link", { name: "Already have an account?" })).toHaveAttribute(
        "href",
        routes.sessions.new.path(),
      );
    });

    it("links to password recovery", () => {
      renderPage();

      expect(screen.getByRole("link", { name: "Forgot password?" })).toHaveAttribute(
        "href",
        routes.passwords.new.path(),
      );
    });
  });

  describe("error handling", () => {
    it("renders server-side email and password errors", () => {
      renderPage({
        email_address: null,
        pageErrors: {
          email_address: "Email address can't be blank",
          password: "Password is too short",
        },
      });

      expect(screen.getByText("Email address can't be blank")).toBeInTheDocument();
      expect(screen.getByText("Password is too short")).toBeInTheDocument();
    });
  });

  describe("layout", () => {
    it("wraps the page in the auth layout", () => {
      render(<>{New.layout?.(<div>Signup layout content</div>)}</>);

      expect(document.body).toHaveClass("wbg");
      expect(screen.getByTestId("flash-messages")).toBeInTheDocument();
      expect(screen.getByText("Signup layout content")).toBeInTheDocument();
    });
  });
});

function renderPage({
  email_address = "laura@blacklodge.io",
  pageErrors = {},
}: {
  email_address?: string | null;
  pageErrors?: Record<string, string>;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<New email_address={email_address} />);
}
