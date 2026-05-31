import { fireEvent, render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import SyncModal from "./SyncModal";

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: {
    post: vi.fn<(...args: unknown[]) => unknown>(),
  },
}));

describe("SyncModal", () => {
  it("closes when escape is pressed", () => {
    const onClose = vi.fn<() => void>();

    render(
      <SyncModal
        fetchLimitedLabel="Fetch Limited"
        id="sync-modal"
        onClose={onClose}
        pullPath="/sync"
        title="Sync"
      />,
    );

    expect(screen.getByRole("dialog")).toBeInTheDocument();

    fireEvent.keyDown(window, { key: "Escape" });

    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
