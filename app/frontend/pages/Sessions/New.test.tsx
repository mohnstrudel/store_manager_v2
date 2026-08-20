import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";
import routes from "@/utils/routes";

import New from "./New";

vi.mock("@/components/flash-messages/FlashMessages", () => ({
  default: () => <div data-testid="flash-messages" />,
}));

describe("Sessions/New", () => {
  afterEach(() => {
    document.body.className = "";
  });

  describe("form shell", () => {
    it("renders the sign-in heading and submit button", () => {
      renderPage();

      expect(screen.getByRole("heading", { name: "Sign in with your email" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Sign in" })).toBeInTheDocument();
    });

    it("prefills the email field and renders the password field", () => {
      renderPage();

      expect(screen.getByRole("textbox", { name: "Email address" })).toHaveValue("dale@fbi.gov");
      expect(screen.getByLabelText("Password")).toHaveAttribute("name", "password");
    });

    it("posts to the session create route", () => {
      renderPage();

      const form = screen.getByRole("button", { name: "Sign in" }).closest("form");

      expect(form).toHaveAttribute("action", routes.sessions.create.path());
      expect(form).toHaveAttribute("data-method", "post");
    });
  });

  describe("navigation links", () => {
    it("links to account signup", () => {
      renderPage();

      expect(screen.getByRole("link", { name: "Create new account" })).toHaveAttribute(
        "href",
        routes.signups.new.path(),
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
          email_address: "Email address is invalid",
          password: "Password is incorrect",
        },
      });

      expect(screen.getByText("Email address is invalid")).toBeInTheDocument();
      expect(screen.getByText("Password is incorrect")).toBeInTheDocument();
    });
  });

  describe("layout", () => {
    it("wraps the page in the auth layout", () => {
      render(<>{New.layout?.(<div>Session layout content</div>)}</>);

      expect(document.body).toHaveClass("wbg");
      expect(screen.getByTestId("flash-messages")).toBeInTheDocument();
      expect(screen.getByText("Session layout content")).toBeInTheDocument();
    });
  });
});

function renderPage({
  email_address = "dale@fbi.gov",
  pageErrors = {},
}: {
  email_address?: string | null;
  pageErrors?: Record<string, string>;
} = {}) {
  mockPageProps({ errors: pageErrors });

  return render(<New email_address={email_address} />);
}
