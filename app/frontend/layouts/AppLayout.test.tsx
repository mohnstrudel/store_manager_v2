import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import AppLayout from "./AppLayout";

vi.mock("@/components/app-navigation/AppNavigation", () => ({
  default: () => <nav data-testid="app-navigation" />,
}));

vi.mock("@/components/flash-messages/FlashMessages", () => ({
  default: () => <div data-testid="flash-messages" />,
}));

vi.mock("@/components/breadcrumbs/Breadcrumbs", () => ({
  default: () => <nav data-testid="breadcrumbs" />,
}));

describe("AppLayout", () => {
  it("renders navigation, flash messages, breadcrumbs, and children", () => {
    render(
      <AppLayout>
        <h1>Page Content</h1>
      </AppLayout>,
    );

    expect(screen.getByTestId("app-navigation")).toBeInTheDocument();
    expect(screen.getByTestId("flash-messages")).toBeInTheDocument();
    expect(screen.getByTestId("breadcrumbs")).toBeInTheDocument();
    expect(screen.getByText("Page Content")).toBeInTheDocument();
  });

  it("scrolls to the top when the footer link is clicked", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "scrollTo").mockImplementation(() => {});

    const { container } = render(
      <AppLayout>
        <div />
      </AppLayout>,
    );

    const footerLink = container.querySelector("footer a")!;
    await user.click(footerLink);

    expect(window.scrollTo).toHaveBeenCalledWith({ top: 0 });
  });
});
