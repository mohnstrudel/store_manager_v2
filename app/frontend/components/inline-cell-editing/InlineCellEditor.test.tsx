import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { InlineCellForm, InlineCellTd, InlineCellTrigger } from "./InlineCellEditor";

describe("InlineCellEditor", () => {
  describe("InlineCellTd", () => {
    it("renders children inside a table cell", () => {
      render(
        <table>
          <tbody>
            <tr>
              <InlineCellTd>content</InlineCellTd>
            </tr>
          </tbody>
        </table>,
      );

      expect(screen.getByRole("cell")).toHaveTextContent("content");
    });

    it("calls onOpen when clicked", async () => {
      const user = userEvent.setup();
      const onOpen = vi.fn<() => void>();

      render(
        <table>
          <tbody>
            <tr>
              <InlineCellTd onOpen={onOpen}>cell</InlineCellTd>
            </tr>
          </tbody>
        </table>,
      );

      await user.click(screen.getByRole("cell"));

      expect(onOpen).toHaveBeenCalled();
    });

    it("stops click propagation so row navigation does not fire", async () => {
      const user = userEvent.setup();
      const rowClick = vi.fn<() => void>();

      render(
        <table>
          <tbody>
            <tr onClick={rowClick}>
              <InlineCellTd>cell</InlineCellTd>
            </tr>
          </tbody>
        </table>,
      );

      await user.click(screen.getByRole("cell"));

      expect(rowClick).not.toHaveBeenCalled();
    });
  });

  describe("InlineCellTrigger", () => {
    it("renders the trigger button and display content", () => {
      render(
        <InlineCellTrigger ariaLabel="Edit name" onOpen={vi.fn<() => void>()}>
          Current value
        </InlineCellTrigger>,
      );

      expect(screen.getByRole("button", { name: "Edit" })).toBeInTheDocument();
      expect(screen.getByText("Current value")).toBeInTheDocument();
    });

    it("calls onOpen when the Edit button is clicked", async () => {
      const user = userEvent.setup();
      const onOpen = vi.fn<() => void>();

      render(
        <InlineCellTrigger ariaLabel="Edit name" onOpen={onOpen}>
          value
        </InlineCellTrigger>,
      );

      await user.click(screen.getByRole("button", { name: "Edit" }));

      expect(onOpen).toHaveBeenCalled();
    });
  });

  describe("InlineCellForm", () => {
    it("renders Save and Exit buttons", () => {
      render(
        <InlineCellForm onCancel={vi.fn<() => void>()} onSave={vi.fn<() => void>()}>
          <input aria-label="Value" />
        </InlineCellForm>,
      );

      expect(screen.getByRole("button", { name: "Save" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Exit" })).toBeInTheDocument();
    });

    it("calls onSave when the form is submitted", async () => {
      const user = userEvent.setup();
      const onSave = vi.fn<() => void>();

      render(
        <InlineCellForm onCancel={vi.fn<() => void>()} onSave={onSave}>
          <input aria-label="Value" />
        </InlineCellForm>,
      );

      await user.click(screen.getByRole("button", { name: "Save" }));

      expect(onSave).toHaveBeenCalled();
    });

    it("calls onCancel when Exit is clicked", async () => {
      const user = userEvent.setup();
      const onCancel = vi.fn<() => void>();

      render(
        <InlineCellForm onCancel={onCancel} onSave={vi.fn<() => void>()}>
          <input aria-label="Value" />
        </InlineCellForm>,
      );

      await user.click(screen.getByRole("button", { name: "Exit" }));

      expect(onCancel).toHaveBeenCalled();
    });
  });
});
