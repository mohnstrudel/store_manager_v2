import { act, cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { emitRouterEvent, mockPage, routerListenerCount } from "@/test/mocks/inertia";

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
  afterEach(() => {
    cleanup();
    vi.useRealTimers();
  });

  describe("flash", () => {
    it("shows a notice flashed with the first page load, with its link", async () => {
      mockPage({
        flash: {
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
      expect(screen.getByRole("link", { name: "jobs dashboard" })).toHaveAttribute(
        "target",
        "_blank",
      );
    });

    it("shows an alert flashed with the first page load", async () => {
      mockPage({ flash: { alert: "You don't have permission" } });

      render(<Notifications />);

      expect(await screen.findByText("You don't have permission")).toBeInTheDocument();
    });

    it("shows a notice flashed by a later response", async () => {
      render(<Notifications />);

      act(() => emitRouterEvent("flash", { flash: { notice: "Purchase Variant was repaired" } }));

      expect(await screen.findByText("Purchase Variant was repaired")).toBeInTheDocument();
    });

    it("shows a flash once when the page already carries the one it announces", async () => {
      const flash = { notice: "Purchase Variant was repaired" };
      mockPage({ flash });
      render(<Notifications />);

      act(() => emitRouterEvent("flash", { flash }));

      expect(await screen.findAllByText("Purchase Variant was repaired")).toHaveLength(1);
    });

    it("shows two responses that flash the same words twice", async () => {
      render(<Notifications />);

      act(() => emitRouterEvent("flash", { flash: { notice: "Variant assignment is repaired" } }));
      act(() => emitRouterEvent("flash", { flash: { notice: "Variant assignment is repaired" } }));

      expect(await screen.findAllByText("Variant assignment is repaired")).toHaveLength(2);
    });

    it("does not show the flash again when the page is set again with a copy of it", async () => {
      mockPage({ flash: { notice: "Started." } });
      const { rerender } = render(<Notifications />);
      await screen.findByText("Started.");

      mockPage({ flash: { notice: "Started." } });
      rerender(<Notifications />);

      expect(screen.getAllByText("Started.")).toHaveLength(1);
    });

    it("shows nothing when the page has no flash", async () => {
      render(<Notifications />);
      await act(async () => {});

      expect(screen.queryAllByRole("button", { name: "Close notification" })).toHaveLength(0);
    });

    it("ignores flash entries it cannot show", async () => {
      mockPage({ flash: { alert: { message: 7 }, notice: 42, other: "Not a notification" } });

      render(<Notifications />);
      await act(async () => {});

      expect([
        screen.queryByText("Not a notification"),
        screen.queryAllByRole("button", { name: "Close notification" }),
      ]).toEqual([null, []]);
    });

    it("stops listening for flashes once it unmounts", () => {
      const { unmount } = render(<Notifications />);
      const listening = routerListenerCount("flash");

      unmount();

      expect([listening, routerListenerCount("flash")]).toEqual([1, 0]);
    });
  });

  describe("live notifications", () => {
    it("does not subscribe unless asked", async () => {
      render(<Notifications />);
      await act(async () => {});

      expect(cable.create).not.toHaveBeenCalled();
    });

    it("keeps a live job notification on screen until it is closed", async () => {
      const { unmount } = render(<Notifications live />);
      const received = await subscribedReceiver();

      vi.useFakeTimers();
      act(() => received({ kind: "success", message: "Shopify sales pull finished." }));
      act(() => {
        vi.advanceTimersByTime(60_000);
      });

      expect(screen.getByText("Shopify sales pull finished.")).toBeInTheDocument();

      unmount();
      expect(cable.disconnect).toHaveBeenCalled();
    });

    it("shows a live alert with its link", async () => {
      render(<Notifications live />);
      const received = await subscribedReceiver();

      act(() =>
        received({
          kind: "alert",
          link: { href: "/jobs/statuses", label: "Open the jobs dashboard" },
          message: "Shopify sales pull failed.",
        }),
      );

      expect(
        await screen.findByText("Shopify sales pull failed.", { exact: false }),
      ).toBeInTheDocument();
      expect(screen.getByRole("link", { name: "Open the jobs dashboard" })).toHaveAttribute(
        "href",
        "/jobs/statuses",
      );
    });

    it("ignores live messages that are not a notice or an alert", async () => {
      render(<Notifications live />);
      const received = await subscribedReceiver();

      act(() => received({ kind: "banner", message: "Not shown" }));
      act(() => received({ message: "Has no kind" }));
      act(() => received({ kind: "notice", message: 7 }));
      act(() => received("Not shown"));
      act(() => received(null));

      expect(screen.queryAllByRole("button", { name: "Close notification" })).toHaveLength(0);
    });
  });
});

async function subscribedReceiver() {
  await vi.waitFor(() =>
    expect(cable.create).toHaveBeenCalledWith("NotificationsChannel", expect.anything()),
  );

  return cable.create.mock.calls[0][1].received;
}
