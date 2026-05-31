import { EditorContent, useEditor } from "@tiptap/react";
import { useCallback, useState } from "react";
import { StarterKit } from "@tiptap/starter-kit";
import { Underline } from "@tiptap/extension-underline";
import { TextAlign } from "@tiptap/extension-text-align";
import { Link } from "@tiptap/extension-link";

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

export default function TiptapEditor({ defaultValue, name }: TiptapEditorProps) {
  const { editor, html, runToolbarAction } = useTiptapDescriptionEditor(defaultValue);

  if (!editor) return null;

  return (
    <>
      <input name={name} type="hidden" value={html} />
      <div className="tiptap-editor border border-gray-300 dark:border-gray-600 rounded overflow-hidden">
        <div className="tiptap-toolbar flex flex-wrap gap-1 p-2 bg-gray-50 dark:bg-gray-800 border-b border-gray-300 dark:border-gray-600">
          <ToolbarButton
            action="bold"
            active={editor.isFocused && editor.isActive("bold")}
            label="B"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="italic"
            active={editor.isFocused && editor.isActive("italic")}
            label="I"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="underline"
            active={editor.isFocused && editor.isActive("underline")}
            label="U"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="strike"
            active={editor.isFocused && editor.isActive("strike")}
            label="S̶"
            onAction={runToolbarAction}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            action="heading-2"
            active={editor.isFocused && editor.isActive("heading", { level: 2 })}
            label="H2"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="heading-3"
            active={editor.isFocused && editor.isActive("heading", { level: 3 })}
            label="H3"
            onAction={runToolbarAction}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            action="bullet-list"
            active={editor.isFocused && editor.isActive("bulletList")}
            label="• List"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="ordered-list"
            active={editor.isFocused && editor.isActive("orderedList")}
            label="1. List"
            onAction={runToolbarAction}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            action="align-left"
            active={editor.isFocused && editor.isActive({ textAlign: "left" })}
            label="Left"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="align-center"
            active={editor.isFocused && editor.isActive({ textAlign: "center" })}
            label="Center"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="align-right"
            active={editor.isFocused && editor.isActive({ textAlign: "right" })}
            label="Right"
            onAction={runToolbarAction}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            action="link"
            active={editor.isFocused && editor.isActive("link")}
            label="Link"
            onAction={runToolbarAction}
          />
          <ToolbarButton
            action="unlink"
            disabled={!editor.isActive("link")}
            label="Unlink"
            onAction={runToolbarAction}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton action="undo" label="↩" onAction={runToolbarAction} />
          <ToolbarButton action="redo" label="↪" onAction={runToolbarAction} />
        </div>
        <EditorContent
          className="tiptap_content rich_text font-nunito prose prose-sm dark:prose-invert max-w-none p-4 min-h-48 [&_.ProseMirror]:outline-none"
          editor={editor}
        />
      </div>
    </>
  );
}

function useTiptapDescriptionEditor(defaultValue: string) {
  const [html, setHtml] = useState(defaultValue);
  const [, rerender] = useState(0);

  const editor = useEditor({
    extensions: [
      StarterKit.configure({
        heading: { levels: [2, 3, 4] },
      }),
      Underline,
      TextAlign.configure({ types: ["heading", "paragraph"] }),
      Link.configure({ openOnClick: false }),
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

    const attributes = editor.getAttributes("link");
    const previousUrl = typeof attributes.href === "string" ? attributes.href : undefined;
    const url = window.prompt("Enter URL", previousUrl ?? "");
    if (url === null) return;

    if (url === "") {
      editor.chain().focus().extendMarkRange("link").unsetLink().run();
    } else {
      editor.chain().focus().extendMarkRange("link").setLink({ href: url }).run();
    }
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
