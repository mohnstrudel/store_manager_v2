import { EditorContent, useEditor } from "@tiptap/react";
import { useCallback, useState } from "react";
import { StarterKit } from "@tiptap/starter-kit";
import { TextAlign } from "@tiptap/extension-text-align";

type ToolbarAction =
  | "bold"
  | "italic"
  | "underline"
  | "strike"
  | "heading-2"
  | "heading-3"
  | "bullet-list"
  | "ordered-list"
  | "align-left"
  | "align-center"
  | "align-right"
  | "link"
  | "unlink"
  | "undo"
  | "redo";

type ToolbarButtonProps = {
  action: ToolbarAction;
  active?: boolean;
  disabled?: boolean;
  label: string;
  onAction: (action: ToolbarAction) => void;
};

type TiptapEditorProps = {
  defaultValue: string;
  name: string;
};

type TiptapEditorInstance = NonNullable<ReturnType<typeof useEditor>>;

type ToolbarButtonConfig = {
  action: ToolbarAction;
  isActive?: (editor: TiptapEditorInstance) => boolean;
  isDisabled?: (editor: TiptapEditorInstance) => boolean;
  label: string;
};

const TOOLBAR_GROUPS: ToolbarButtonConfig[][] = [
  [
    {
      action: "bold",
      isActive: (editor) => editor.isActive("bold"),
      label: "B",
    },
    {
      action: "italic",
      isActive: (editor) => editor.isActive("italic"),
      label: "I",
    },
    {
      action: "underline",
      isActive: (editor) => editor.isActive("underline"),
      label: "U",
    },
    {
      action: "strike",
      isActive: (editor) => editor.isActive("strike"),
      label: "S̶",
    },
  ],
  [
    {
      action: "heading-2",
      isActive: (editor) => editor.isActive("heading", { level: 2 }),
      label: "H2",
    },
    {
      action: "heading-3",
      isActive: (editor) => editor.isActive("heading", { level: 3 }),
      label: "H3",
    },
  ],
  [
    {
      action: "bullet-list",
      isActive: (editor) => editor.isActive("bulletList"),
      label: "• List",
    },
    {
      action: "ordered-list",
      isActive: (editor) => editor.isActive("orderedList"),
      label: "1. List",
    },
  ],
  [
    {
      action: "align-left",
      isActive: (editor) => editor.isActive({ textAlign: "left" }),
      label: "Left",
    },
    {
      action: "align-center",
      isActive: (editor) => editor.isActive({ textAlign: "center" }),
      label: "Center",
    },
    {
      action: "align-right",
      isActive: (editor) => editor.isActive({ textAlign: "right" }),
      label: "Right",
    },
  ],
  [
    {
      action: "link",
      isActive: (editor) => editor.isActive("link"),
      label: "Link",
    },
    {
      action: "unlink",
      isDisabled: (editor) => !editor.isActive("link"),
      label: "Unlink",
    },
  ],
  [
    { action: "undo", label: "↩" },
    { action: "redo", label: "↪" },
  ],
];

export default function TiptapEditor({ defaultValue, name }: TiptapEditorProps) {
  const { editor, html, runToolbarAction } = useTiptapDescriptionEditor(defaultValue);

  if (!editor) return null;

  return (
    <>
      <input name={name} type="hidden" value={html} />
      <RichTextEditor editor={editor} onToolbarAction={runToolbarAction} />
    </>
  );
}

type RichTextEditorProps = {
  editor: TiptapEditorInstance;
  onToolbarAction: (action: ToolbarAction) => void;
};

function RichTextEditor({ editor, onToolbarAction }: RichTextEditorProps) {
  return (
    <div className="tiptap-editor border border-gray-300 dark:border-gray-600 rounded overflow-hidden">
      <Toolbar editor={editor} onToolbarAction={onToolbarAction} />
      <EditorContent
        className="tiptap_content rich_text font-nunito prose prose-sm dark:prose-invert max-w-none p-4 min-h-48 [&_.ProseMirror]:outline-none"
        editor={editor}
      />
    </div>
  );
}

type ToolbarProps = {
  editor: TiptapEditorInstance;
  onToolbarAction: (action: ToolbarAction) => void;
};

function Toolbar({ editor, onToolbarAction }: ToolbarProps) {
  return (
    <div className="tiptap-toolbar flex flex-wrap gap-1 p-2 bg-gray-50 dark:bg-gray-800 border-b border-gray-300 dark:border-gray-600">
      {TOOLBAR_GROUPS.map((buttons, index) => (
        <ToolbarGroup
          buttons={buttons}
          editor={editor}
          key={buttons.map((button) => button.action).join("-")}
          onToolbarAction={onToolbarAction}
          separated={index > 0}
        />
      ))}
    </div>
  );
}

type ToolbarGroupProps = {
  buttons: ToolbarButtonConfig[];
  editor: TiptapEditorInstance;
  onToolbarAction: (action: ToolbarAction) => void;
  separated: boolean;
};

function ToolbarGroup({ buttons, editor, onToolbarAction, separated }: ToolbarGroupProps) {
  return (
    <>
      {separated && <ToolbarSeparator />}
      {buttons.map((button) => (
        <ToolbarButton
          action={button.action}
          active={isToolbarButtonActive(button, editor)}
          disabled={button.isDisabled?.(editor)}
          key={button.action}
          label={button.label}
          onAction={onToolbarAction}
        />
      ))}
    </>
  );
}

function ToolbarSeparator() {
  return <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />;
}

function useTiptapDescriptionEditor(defaultValue: string) {
  const [html, setHtml] = useState(defaultValue);
  const [, rerender] = useState(0);

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [2, 3, 4] },
        link: { openOnClick: false },
      }),
      TextAlign.configure({ types: ["heading", "paragraph"] }),
    ],
    content: defaultValue,
    onUpdate({ editor: currentEditor }) {
      setHtml(currentEditor.getHTML());
    },
    onSelectionUpdate() {
      rerender((count) => count + 1);
    },
    onFocus() {
      rerender((count) => count + 1);
    },
    onBlur() {
      rerender((count) => count + 1);
    },
  });

  const setLink = useCallback(() => {
    if (!editor) return;

    promptForLink(editor);
  }, [editor]);

  const runToolbarAction = useCallback(
    (action: ToolbarAction) => {
      if (!editor) return;

      switch (action) {
        case "bold":
          editor.chain().focus().toggleBold().run();
          return;
        case "italic":
          editor.chain().focus().toggleItalic().run();
          return;
        case "underline":
          editor.chain().focus().toggleUnderline().run();
          return;
        case "strike":
          editor.chain().focus().toggleStrike().run();
          return;
        case "heading-2":
          editor.chain().focus().toggleHeading({ level: 2 }).run();
          return;
        case "heading-3":
          editor.chain().focus().toggleHeading({ level: 3 }).run();
          return;
        case "bullet-list":
          editor.chain().focus().toggleBulletList().run();
          return;
        case "ordered-list":
          editor.chain().focus().toggleOrderedList().run();
          return;
        case "align-left":
          editor.chain().focus().setTextAlign("left").run();
          return;
        case "align-center":
          editor.chain().focus().setTextAlign("center").run();
          return;
        case "align-right":
          editor.chain().focus().setTextAlign("right").run();
          return;
        case "link":
          setLink();
          return;
        case "unlink":
          editor.chain().focus().unsetLink().run();
          return;
        case "undo":
          editor.chain().focus().undo().run();
          return;
        case "redo":
          editor.chain().focus().redo().run();
      }
    },
    [editor, setLink],
  );

  return { editor, html, runToolbarAction };
}

function promptForLink(editor: TiptapEditorInstance) {
  const previousUrl = currentLinkUrl(editor);
  const url = window.prompt("Enter URL", previousUrl ?? "");
  if (url === null) return;

  if (url === "") {
    editor.chain().focus().extendMarkRange("link").unsetLink().run();
    return;
  }

  editor.chain().focus().extendMarkRange("link").setLink({ href: url }).run();
}

function currentLinkUrl(editor: TiptapEditorInstance) {
  const attributes = editor.getAttributes("link");

  return typeof attributes.href === "string" ? attributes.href : undefined;
}

function ToolbarButton({ action, active, disabled, label, onAction }: ToolbarButtonProps) {
  const handleClick = useCallback(() => onAction(action), [action, onAction]);

  return (
    <button
      className={`px-2 py-1 text-sm rounded border ${active ? "bg-gray-800 text-white dark:bg-gray-200 dark:text-gray-900 border-transparent" : "bg-white dark:bg-gray-900 border-gray-300 dark:border-gray-600 hover:bg-gray-100 dark:hover:bg-gray-700"} ${disabled ? "opacity-50 cursor-not-allowed" : ""}`}
      disabled={disabled}
      onClick={handleClick}
      type="button"
    >
      {label}
    </button>
  );
}

function isToolbarButtonActive(button: ToolbarButtonConfig, editor: TiptapEditorInstance) {
  return editor.isFocused && button.isActive?.(editor);
}
