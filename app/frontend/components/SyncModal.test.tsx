import { router } from "@inertiajs/react";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import SyncModal from "./SyncModal";

describe("SyncModal", () => {
  it("fetches every record without params and closes the dialog", async () => {
    const user = userEvent.setup();
    const onClose = vi.fn<() => void>();

    render(<SyncModal id="sync-modal" onClose={onClose} pullPath="/sync" title="Sync" />);

    await user.click(screen.getByRole("button", { name: "Fetch Everything" }));

    expect(router.post).toHaveBeenCalledWith("/sync", {});
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("fetches only the changes and closes the dialog", async () => {
    const user = userEvent.setup();
    const onClose = vi.fn<() => void>();

    render(<SyncModal id="sync-modal" onClose={onClose} pullPath="/sync" title="Sync" />);

    await user.click(screen.getByRole("button", { name: "Fetch Changes" }));

    expect(router.post).toHaveBeenCalledWith("/sync", { scope: "changes" });
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("offers Fetch Everything first and in blue, then Fetch Changes", () => {
    render(
      <SyncModal id="sync-modal" onClose={vi.fn<() => void>()} pullPath="/sync" title="Sync" />,
    );

    const everything = screen.getByRole("button", { name: "Fetch Everything" });
    const changes = screen.getByRole("button", { name: "Fetch Changes" });

    expect(everything).toHaveClass("btn_blue");
    expect(changes).not.toHaveClass("btn_blue");
    expect(
      everything.compareDocumentPosition(changes) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy();
  });

  it("shows the last completed pull under the title", () => {
    render(
      <SyncModal
        id="sync-modal"
        lastSyncAt="Last fetched at 5 January at 10:00"
        onClose={vi.fn<() => void>()}
        pullPath="/sync"
        title="Sync"
      />,
    );

    expect(screen.getByText("Last fetched at 5 January at 10:00")).toBeInTheDocument();
  });
});
