import { useState } from "react";

type CopyToClipboardButtonProps = {
  className?: string;
  label?: string;
  text: string;
};

export default function CopyToClipboardButton({
  className = "",
  label = "Copy",
  text,
}: CopyToClipboardButtonProps) {
  const [copied, setCopied] = useState(false);

  async function copy() {
    if (!text) return;

    await navigator.clipboard.writeText(text);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 800);
  }

  return (
    <button
      className={["btn-rounded no-events cursor-pointer transition-all ease-out", copied ? "btn-amber" : "", className]
        .filter(Boolean)
        .join(" ")}
      data-copy-to-clipboard-text-value={text}
      onClick={copy}
      title="Copy to clipboard"
      type="button"
    >
      <span className="icn h-4 w-4">{copied ? "👍" : "📋"}</span>
      <span className="text-nowrap">{copied ? "Done" : label}</span>
    </button>
  );
}
