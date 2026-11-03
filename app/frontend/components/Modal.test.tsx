import { fireEvent, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";

import Modal from "./Modal";

describe("Modal", () => {
  it("opens as a modal dialog named by its title, with an optional subtitle", () => {
    renderModal({ subtitle: "Last sync: today" });

    const dialog = screen.getByRole("dialog", { name: "Edit tags" });

    expect(dialog).toHaveAttribute("open");
    expect(dialog).toHaveTextContent("Last sync: today");
    expect(screen.getByText("Body")).toBeInTheDocument();
  });

  it("closes from the Close button", async () => {
    const user = userEvent.setup();
    const { onClose } = renderModal();

    await user.click(screen.getByRole("button", { name: "Close" }));

    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("hands the Escape close request to the owner instead of closing itself", () => {
    const { onClose } = renderModal();
    const cancel = new Event("cancel", { cancelable: true });

    fireEvent(screen.getByRole("dialog"), cancel);

    expect(cancel.defaultPrevented).toBe(true);
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("closes on a backdrop click but not on a click inside the content", async () => {
    const user = userEvent.setup();
    const { onClose } = renderModal();

    await user.click(screen.getByText("Body"));
    expect(onClose).not.toHaveBeenCalled();

    await user.click(screen.getByRole("dialog"));
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("ignores every close request while busy", async () => {
    const user = userEvent.setup();
    const { onClose } = renderModal({ isBusy: true });
    const cancel = new Event("cancel", { cancelable: true });

    fireEvent(screen.getByRole("dialog"), cancel);
    await user.click(screen.getByRole("dialog"));

    expect(screen.getByRole("button", { name: "Close" })).toBeDisabled();
    expect(cancel.defaultPrevented).toBe(true);
    expect(onClose).not.toHaveBeenCalled();
  });

  it("closes the native dialog on unmount so the browser restores focus", () => {
    const close = vi.spyOn(HTMLDialogElement.prototype, "close");
    const { unmount } = renderModal();

    unmount();

    expect(close).toHaveBeenCalledTimes(1);
  });

  it("renders the footer after the body inside the dialog", () => {
    renderModal({ footer: <button type="button">Save</button> });

    const footerButton = within(screen.getByRole("dialog")).getByRole("button", { name: "Save" });

    expect(
      screen.getByText("Body").compareDocumentPosition(footerButton) &
        Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy();
  });
});

function renderModal({
  footer,
  isBusy = false,
  subtitle,
}: { footer?: ReactNode; isBusy?: boolean; subtitle?: string } = {}) {
  const onClose = vi.fn<() => void>();
  const view = render(
    <Modal footer={footer} isBusy={isBusy} onClose={onClose} subtitle={subtitle} title="Edit tags">
      <p>Body</p>
    </Modal>,
  );

  return { ...view, onClose };
}
