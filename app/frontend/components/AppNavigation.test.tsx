import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import AppNavigation from "./AppNavigation";

const page = vi.hoisted(() => ({
  props: {
    flash: { notice: null, alert: null },
    csrf_token: "token",
  },
}));

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: {
    post: vi.fn<(...args: unknown[]) => unknown>(),
  },
  usePage: () => page,
}));

describe("AppNavigation", () => {
  it("renders without a shared auth payload", () => {
    render(<AppNavigation />);

    expect(screen.getByText("StoreMate")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Dashboard" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Log Out" })).toBeInTheDocument();
  });
});
