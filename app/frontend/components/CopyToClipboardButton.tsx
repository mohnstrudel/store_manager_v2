import { useCallback, useState, type MouseEvent } from "react";

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
  const { copied, copy } = useClipboardCopy(text);

  const handleClick = useCallback(
    (event: MouseEvent<HTMLButtonElement>) => {
      event.stopPropagation();
      void copy();
    },
    [copy],
  );

  return (
    <button
      className={`btn_rounded no_events cursor-pointer transition-all ease-out ${className}`}
      data-copied={copied || undefined}
      data-copy-to-clipboard-text-value={text}
      onClick={handleClick}
      title="Copy to clipboard"
      type="button"
    >
      <span className="icn h-4 w-4">{copied ? "👍" : "📋"}</span>
      <span className="text-nowrap">{copied ? "Done" : label}</span>
    </button>
  );
}

function useClipboardCopy(text: string) {
  const [copied, setCopied] = useState(false);

  const copy = useCallback(async () => {
    if (!text) return;

    await navigator.clipboard.writeText(text);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 800);
  }, [text]);

  return { copied, copy };
}
