import { fireEvent, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import SyncModal from "./SyncModal";

const postSync = vi.hoisted(() => vi.fn<(...args: unknown[]) => unknown>());

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: {
    post: postSync,
  },
}));

describe("SyncModal", () => {
  beforeEach(() => {
    postSync.mockClear();
  });

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

  it("fetches every record and closes the dialog", async () => {
    const user = userEvent.setup();
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

    await user.click(screen.getByRole("button", { name: "Fetch Everything" }));

    expect(postSync).toHaveBeenCalledWith("/sync", {});
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("fetches recent records and closes the dialog", async () => {
    const user = userEvent.setup();
    const onClose = vi.fn<() => void>();

    render(
      <SyncModal
        fetchLimitedLabel="Fetch Last 100 Records"
        id="sync-modal"
        onClose={onClose}
        pullPath="/sync"
        title="Sync"
      />,
    );

    await user.click(screen.getByRole("button", { name: "Fetch Last 100 Records" }));

    expect(postSync).toHaveBeenCalledWith("/sync", { limit: 100 });
    expect(onClose).toHaveBeenCalledTimes(1);
  });
});
