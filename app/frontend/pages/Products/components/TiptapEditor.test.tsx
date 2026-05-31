import { act, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import TiptapEditor from "./TiptapEditor";

type UseEditorOptions = {
  onUpdate: (props: { editor: { getHTML: () => string } }) => void;
};

let latestOptions: UseEditorOptions | null = null;

const chain = {
  extendMarkRange: () => chain,
  focus: () => chain,
  redo: () => chain,
  run: () => true,
  setLink: () => chain,
  setTextAlign: () => chain,
  toggleBold: () => chain,
  toggleBulletList: () => chain,
  toggleHeading: () => chain,
  toggleItalic: () => chain,
  toggleOrderedList: () => chain,
  toggleStrike: () => chain,
  toggleUnderline: () => chain,
  undo: () => chain,
  unsetLink: () => chain,
};

vi.mock("@tiptap/react", () => ({
  EditorContent: () => <div data-testid="editor-content" />,
  useEditor: (options: UseEditorOptions) => {
    latestOptions = options;

    return {
      chain: () => chain,
      getAttributes: () => ({}),
      isActive: () => false,
    };
  },
}));

vi.mock("@tiptap/starter-kit", () => ({
  StarterKit: { configure: () => "starter-kit" },
  default: { configure: () => "starter-kit" },
}));

vi.mock("@tiptap/extension-underline", () => ({
  Underline: "underline",
  default: "underline",
}));

vi.mock("@tiptap/extension-text-align", () => ({
  TextAlign: { configure: () => "text-align" },
  default: { configure: () => "text-align" },
}));

vi.mock("@tiptap/extension-link", () => ({
  Link: { configure: () => "link" },
  default: { configure: () => "link" },
}));

describe("TiptapEditor", () => {
  it("renders a named hidden input with the initial HTML", () => {
    render(<TiptapEditor defaultValue="<p>Initial</p>" name="product[description]" />);

    expect(screen.getByTestId("editor-content")).toBeInTheDocument();
    expect(document.querySelector('input[name="product[description]"]')).toHaveValue(
      "<p>Initial</p>",
    );
  });

  it("updates the hidden input from editor HTML changes", () => {
    render(<TiptapEditor defaultValue="<p>Initial</p>" name="product[description]" />);

    act(() => {
      latestOptions?.onUpdate({ editor: { getHTML: () => "<p>Changed</p>" } });
    });

    expect(document.querySelector('input[name="product[description]"]')).toHaveValue(
      "<p>Changed</p>",
    );
  });
});
