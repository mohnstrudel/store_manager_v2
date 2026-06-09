import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import AuthLayout from "./AuthLayout";

vi.mock("@/components/flash-messages/FlashMessages", () => ({
  default: () => <div data-testid="flash-messages" />,
}));

describe("AuthLayout", () => {
  afterEach(() => {
    cleanup();
    document.body.className = "";
  });

  it("adds the wbg class to the body while mounted", () => {
    const { unmount } = render(
      <AuthLayout>
        <div>Sign in form</div>
      </AuthLayout>,
    );

    expect(document.body).toHaveClass("wbg");
    expect(screen.getByTestId("flash-messages")).toBeInTheDocument();
    expect(screen.getByText("Sign in form")).toBeVisible();

    unmount();

    expect(document.body).not.toHaveClass("wbg");
  });
});
