import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import Notifications from "./Notifications";

const cable = vi.hoisted(() => ({
  create: vi.fn<(channel: string, mixin: { received: (data: unknown) => void }) => void>(),
  disconnect: vi.fn<() => void>(),
}));

vi.mock("@rails/actioncable", () => ({
  createConsumer: () => ({
    disconnect: cable.disconnect,
    subscriptions: { create: cable.create },
  }),
}));

describe("Notifications", () => {
  beforeEach(() => {
    mockPageProps({ flash: { alert: null, notice: null } });
  });

  afterEach(() => {
    cleanup();
    vi.useRealTimers();
  });

  it("shows a flash notice with its link", async () => {
    mockPageProps({
      flash: {
        alert: null,
        notice: {
          link: { href: "/jobs/statuses", label: "jobs dashboard" },
          message: "Started.",
        },
      },
    });

    render(<Notifications />);

    expect(await screen.findByText("Started.", { exact: false })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "jobs dashboard" })).toHaveAttribute(
      "href",
      "/jobs/statuses",
    );
  });

  it("shows a flash alert", async () => {
    mockPageProps({
      flash: { alert: "You don't have permission", notice: null },
    });

    render(<Notifications />);

    expect(await screen.findByText("You don't have permission")).toBeInTheDocument();
  });

  it("does not subscribe to live notifications unless asked", async () => {
    render(<Notifications />);
    await act(async () => {});

    expect(cable.create).not.toHaveBeenCalled();
  });

  it("keeps a live job notification on screen until it is closed", async () => {
    const { unmount } = render(<Notifications live />);
    await vi.waitFor(() =>
      expect(cable.create).toHaveBeenCalledWith("NotificationsChannel", expect.anything()),
    );
    const { received } = cable.create.mock.calls[0][1];

    vi.useFakeTimers();
    act(() => received({ kind: "notice", message: "Shopify sales pull finished." }));
    act(() => {
      vi.advanceTimersByTime(60_000);
    });

    expect(screen.getByText("Shopify sales pull finished.")).toBeInTheDocument();

    unmount();
    expect(cable.disconnect).toHaveBeenCalled();
  });
});
