import { fireEvent, render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import AppNavigation from "./AppNavigation";

const page = vi.hoisted(() => ({
  props: {
    auth: {
      user: {
        id: 1,
        email_address: "admin@example.com",
        role: "admin",
      },
    },
    flash: { notice: null, alert: null },
    csrf_token: "token",
  },
}));

vi.mock("@inertiajs/react", () => ({
  Link: ({
    children,
    href,
    component: _component,
    pageProps: _pageProps,
    prefetch: _prefetch,
    onClick,
    ...props
  }: {
    children: ReactNode;
    href: string;
    component?: string;
    pageProps?: Record<string, unknown>;
    prefetch?: boolean;
    onClick?: (event: { preventDefault(): void }) => void;
  }) => (
    <a
      href={href}
      {...props}
      onClick={(event) => {
        event.preventDefault();
        onClick?.(event);
      }}
    >
      {children}
    </a>
  ),
  router: {
    post: vi.fn<(...args: unknown[]) => unknown>(),
  },
  usePage: () => page,
}));

describe("AppNavigation", () => {
  beforeEach(() => {
    page.props.auth.user = {
      id: 1,
      email_address: "admin@example.com",
      role: "admin",
    };
  });

  it("renders the main navigation and opens and dismisses the overflow menu", async () => {
    const user = userEvent.setup();

    render(<AppNavigation />);

    const toggle = screen.getByRole("button", { name: "More navigation links" });

    expect(screen.getByRole("navigation", { name: "Main navigation" })).toBeInTheDocument();
    expect(screen.getByText("StoreMate")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Dashboard" })).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();

    await user.click(toggle);

    expect(screen.getByRole("link", { name: "Brands" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Users" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Log Out" })).toBeInTheDocument();

    fireEvent.pointerDown(document.body);

    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();

    await user.click(toggle);

    expect(screen.getByRole("link", { name: "Brands" })).toBeInTheDocument();

    fireEvent.keyDown(window, { key: "Escape" });

    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();
  });

  it("closes the overflow menu when a navigation link is selected", async () => {
    const user = userEvent.setup();

    render(<AppNavigation />);

    await user.click(screen.getByRole("button", { name: "More navigation links" }));
    await user.click(screen.getByRole("link", { name: "Brands" }));

    expect(screen.queryByRole("link", { name: "Brands" })).not.toBeInTheDocument();
  });

  it("renders a guest-only navigation", () => {
    page.props.auth.user = {
      id: 1,
      email_address: "guest@example.com",
      role: "guest",
    };

    render(<AppNavigation />);

    expect(screen.queryByRole("button", { name: "More navigation links" })).not.toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Dashboard" })).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Log Out" })).toBeInTheDocument();
  });
});
