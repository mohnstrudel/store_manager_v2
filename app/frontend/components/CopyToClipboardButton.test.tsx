import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import CopyToClipboardButton from "./CopyToClipboardButton";

const writeText = vi.fn<() => Promise<void>>();

describe("CopyToClipboardButton", () => {
  beforeEach(() => {
    writeText.mockResolvedValue(undefined);
    Object.defineProperty(navigator, "clipboard", {
      value: { writeText },
      configurable: true,
    });
  });

  it("renders the default Copy label", () => {
    render(<CopyToClipboardButton text="hello" />);

    expect(screen.getByRole("button", { name: /Copy/ })).toBeInTheDocument();
  });

  it("renders a custom label", () => {
    render(<CopyToClipboardButton text="hello" label="Copy ID" />);

    expect(screen.getByRole("button", { name: /Copy ID/ })).toBeInTheDocument();
  });

  it("writes the text to the clipboard on click", async () => {
    render(<CopyToClipboardButton text="abc-123" />);

    fireEvent.click(screen.getByRole("button"));

    await waitFor(() => expect(writeText).toHaveBeenCalledWith("abc-123"));
  });

  it("switches to 'Done' after copying", async () => {
    const user = userEvent.setup();

    render(<CopyToClipboardButton text="abc-123" />);

    await user.click(screen.getByRole("button"));

    expect(screen.getByRole("button", { name: /Done/ })).toBeInTheDocument();
  });

  describe("when text is empty", () => {
    it("does not write to the clipboard", async () => {
      render(<CopyToClipboardButton text="" />);

      fireEvent.click(screen.getByRole("button"));

      await Promise.resolve();

      expect(writeText).not.toHaveBeenCalled();
    });
  });
});
