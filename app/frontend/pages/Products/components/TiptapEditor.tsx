import { useEditor, EditorContent } from "@tiptap/react";
import { useState } from "react";
import StarterKit from "@tiptap/starter-kit";
import Underline from "@tiptap/extension-underline";
import TextAlign from "@tiptap/extension-text-align";
import Link from "@tiptap/extension-link";

type ToolbarButtonProps = {
  active?: boolean;
  disabled?: boolean;
  label: string;
  onClick: () => void;
};

function ToolbarButton({ active, disabled, label, onClick }: ToolbarButtonProps) {
  return (
    <button
      className={[
        "px-2 py-1 text-sm rounded border",
        active
          ? "bg-gray-800 text-white dark:bg-gray-200 dark:text-gray-900 border-transparent"
          : "bg-white dark:bg-gray-900 border-gray-300 dark:border-gray-600 hover:bg-gray-100 dark:hover:bg-gray-700",
        disabled ? "opacity-50 cursor-not-allowed" : "",
      ]
        .filter(Boolean)
        .join(" ")}
      disabled={disabled}
      onClick={onClick}
      type="button"
    >
      {label}
    </button>
  );
}

type TiptapEditorProps = {
  defaultValue: string;
  name: string;
};

export default function TiptapEditor({ defaultValue, name }: TiptapEditorProps) {
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
    onUpdate({ editor }) {
      setHtml(editor.getHTML());
    },
    onSelectionUpdate() {
      rerender((n) => n + 1);
    },
    onFocus() {
      rerender((n) => n + 1);
    },
    onBlur() {
      rerender((n) => n + 1);
    },
  });

  if (!editor) return null;

  function setLink() {
    const prev = editor!.getAttributes("link").href as string | undefined;
    const url = window.prompt("Enter URL", prev ?? "");
    if (url === null) return;
    if (url === "") {
      editor!.chain().focus().extendMarkRange("link").unsetLink().run();
    } else {
      editor!.chain().focus().extendMarkRange("link").setLink({ href: url }).run();
    }
  }

  return (
    <>
      <input name={name} type="hidden" value={html} />
      <div className="tiptap-editor border border-gray-300 dark:border-gray-600 rounded overflow-hidden">
        <div className="tiptap-toolbar flex flex-wrap gap-1 p-2 bg-gray-50 dark:bg-gray-800 border-b border-gray-300 dark:border-gray-600">
          <ToolbarButton
            active={editor.isFocused && editor.isActive("bold")}
            label="B"
            onClick={() => editor.chain().focus().toggleBold().run()}
          />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("italic")}
            label="I"
            onClick={() => editor.chain().focus().toggleItalic().run()}
          />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("underline")}
            label="U"
            onClick={() => editor.chain().focus().toggleUnderline().run()}
          />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("strike")}
            label="S̶"
            onClick={() => editor.chain().focus().toggleStrike().run()}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("heading", { level: 2 })}
            label="H2"
            onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
          />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("heading", { level: 3 })}
            label="H3"
            onClick={() => editor.chain().focus().toggleHeading({ level: 3 }).run()}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("bulletList")}
            label="• List"
            onClick={() => editor.chain().focus().toggleBulletList().run()}
          />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("orderedList")}
            label="1. List"
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            active={editor.isFocused && editor.isActive({ textAlign: "left" })}
            label="Left"
            onClick={() => editor.chain().focus().setTextAlign("left").run()}
          />
          <ToolbarButton
            active={editor.isFocused && editor.isActive({ textAlign: "center" })}
            label="Center"
            onClick={() => editor.chain().focus().setTextAlign("center").run()}
          />
          <ToolbarButton
            active={editor.isFocused && editor.isActive({ textAlign: "right" })}
            label="Right"
            onClick={() => editor.chain().focus().setTextAlign("right").run()}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton
            active={editor.isFocused && editor.isActive("link")}
            label="Link"
            onClick={setLink}
          />
          <ToolbarButton
            disabled={!editor.isActive("link")}
            label="Unlink"
            onClick={() => editor.chain().focus().unsetLink().run()}
          />
          <span className="w-px bg-gray-300 dark:bg-gray-600 mx-1" />
          <ToolbarButton label="↩" onClick={() => editor.chain().focus().undo().run()} />
          <ToolbarButton label="↪" onClick={() => editor.chain().focus().redo().run()} />
        </div>
        <EditorContent
          className="tiptap-content rich-text font-nunito prose prose-sm dark:prose-invert max-w-none p-4 min-h-48 [&_.ProseMirror]:outline-none"
          editor={editor}
        />
      </div>
    </>
  );
}
