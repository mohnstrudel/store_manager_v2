import { render, screen } from "@testing-library/react";
import { act } from "react";
import type { ReactNode } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import FlashMessages from "./FlashMessages";

const flashState = vi.hoisted(() => ({
  flash: {
    alert: null as null | string,
    notice: null as
      | null
      | string
      | {
          message: string;
          link: { href: string; label: string };
        },
  },
}));

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
}));

vi.mock("./useFlash", () => ({
  useFlash: () => flashState.flash,
}));

describe("FlashMessages", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    flashState.flash = { alert: null, notice: null };
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("renders route flash as a top-sliding toast with the regular flash layout", () => {
    flashState.flash = {
      alert: null,
      notice: "Tracking number was successfully updated",
    };

    render(<FlashMessages />);

    expect(screen.getByRole("status")).toHaveClass("flash_toast", "pointer-events-auto");
    expect(screen.getByText("Tracking number was successfully updated")).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Dismiss notification" })).not.toBeInTheDocument();
  });

  it("renders linked route flash as a real destination link", () => {
    flashState.flash = {
      alert: null,
      notice: {
        message: "Success! 2 purchased products moved to:",
        link: { href: "/warehouses/2", label: "Berlin Hub" },
      },
    };

    render(<FlashMessages />);

    expect(screen.getByText("Success! 2 purchased products moved to:")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Berlin Hub" })).toHaveAttribute(
      "href",
      "/warehouses/2",
    );
  });

  it("animates out before auto-dismissing the active flash message", () => {
    flashState.flash = {
      alert: "Could not save shipping company",
      notice: null,
    };

    render(<FlashMessages />);

    expect(screen.getByText("Could not save shipping company")).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(0);
    });

    act(() => {
      vi.advanceTimersByTime(5000);
    });

    expect(screen.getByRole("status")).toHaveClass("opacity-0", "-translate-y-4", "scale-95");
    expect(screen.getByText("Could not save shipping company")).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(300);
    });

    expect(screen.queryByText("Could not save shipping company")).not.toBeInTheDocument();
  });
});
