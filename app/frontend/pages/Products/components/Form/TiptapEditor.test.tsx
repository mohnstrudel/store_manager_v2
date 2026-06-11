import { act, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import TiptapEditor from "./TiptapEditor";

type UseEditorOptions = {
  onUpdate: (props: { editor: { getHTML: () => string } }) => void;
};

type MockChain = {
  extendMarkRange: ReturnType<typeof vi.fn<(mark: string) => MockChain>>;
  focus: ReturnType<typeof vi.fn<() => MockChain>>;
  redo: ReturnType<typeof vi.fn<() => MockChain>>;
  run: ReturnType<typeof vi.fn<() => boolean>>;
  setLink: ReturnType<typeof vi.fn<(attributes: { href: string }) => MockChain>>;
  setTextAlign: ReturnType<typeof vi.fn<(alignment: string) => MockChain>>;
  toggleBold: ReturnType<typeof vi.fn<() => MockChain>>;
  toggleBulletList: ReturnType<typeof vi.fn<() => MockChain>>;
  toggleHeading: ReturnType<typeof vi.fn<(attributes: { level: number }) => MockChain>>;
  toggleItalic: ReturnType<typeof vi.fn<() => MockChain>>;
  toggleOrderedList: ReturnType<typeof vi.fn<() => MockChain>>;
  toggleStrike: ReturnType<typeof vi.fn<() => MockChain>>;
  toggleUnderline: ReturnType<typeof vi.fn<() => MockChain>>;
  undo: ReturnType<typeof vi.fn<() => MockChain>>;
  unsetLink: ReturnType<typeof vi.fn<() => MockChain>>;
};

let latestOptions: UseEditorOptions | null = null;

const editorMocks = vi.hoisted(() => {
  let chain: MockChain;

  chain = {
    extendMarkRange: vi.fn<(mark: string) => MockChain>(() => chain),
    focus: vi.fn<() => MockChain>(() => chain),
    redo: vi.fn<() => MockChain>(() => chain),
    run: vi.fn<() => boolean>(() => true),
    setLink: vi.fn<(attributes: { href: string }) => MockChain>(() => chain),
    setTextAlign: vi.fn<(alignment: string) => MockChain>(() => chain),
    toggleBold: vi.fn<() => MockChain>(() => chain),
    toggleBulletList: vi.fn<() => MockChain>(() => chain),
    toggleHeading: vi.fn<(attributes: { level: number }) => MockChain>(() => chain),
    toggleItalic: vi.fn<() => MockChain>(() => chain),
    toggleOrderedList: vi.fn<() => MockChain>(() => chain),
    toggleStrike: vi.fn<() => MockChain>(() => chain),
    toggleUnderline: vi.fn<() => MockChain>(() => chain),
    undo: vi.fn<() => MockChain>(() => chain),
    unsetLink: vi.fn<() => MockChain>(() => chain),
  };

  return {
    chain,
    chainFactory: vi.fn<() => MockChain>(() => chain),
    getAttributes: vi.fn<() => Record<string, unknown>>(() => ({})),
    isActive: vi.fn<(...args: unknown[]) => boolean>(() => false),
  };
});

vi.mock("@tiptap/react", () => ({
  EditorContent: () => <div data-testid="editor-content" />,
  useEditor: (options: UseEditorOptions) => {
    latestOptions = options;

    return {
      chain: editorMocks.chainFactory,
      getAttributes: editorMocks.getAttributes,
      isActive: editorMocks.isActive,
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

describe("Products/components/Form/TiptapEditor", () => {
  beforeEach(() => {
    latestOptions = null;
  });

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

  it("runs toolbar commands from button clicks", async () => {
    const user = userEvent.setup();
    render(<TiptapEditor defaultValue="<p>Initial</p>" name="product[description]" />);

    await user.click(screen.getByRole("button", { name: "B" }));

    expect(editorMocks.chain.focus).toHaveBeenCalled();
    expect(editorMocks.chain.toggleBold).toHaveBeenCalled();
    expect(editorMocks.chain.run).toHaveBeenCalled();
  });

  it("prompts for a link URL and applies it", async () => {
    const user = userEvent.setup();
    const prompt = vi.spyOn(window, "prompt").mockReturnValue("https://example.com");
    render(<TiptapEditor defaultValue="<p>Initial</p>" name="product[description]" />);

    await user.click(screen.getByRole("button", { name: "Link" }));

    expect(prompt).toHaveBeenCalledWith("Enter URL", "");
    expect(editorMocks.chain.extendMarkRange).toHaveBeenCalledWith("link");
    expect(editorMocks.chain.setLink).toHaveBeenCalledWith({
      href: "https://example.com",
    });
    expect(editorMocks.chain.run).toHaveBeenCalled();
  });
});
