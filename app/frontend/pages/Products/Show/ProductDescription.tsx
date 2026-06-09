import { useMemo } from "react";

type ProductDescriptionProps = {
  html: string;
};

export default function ProductDescription({ html }: ProductDescriptionProps) {
  const dangerousHtml = useMemo(() => ({ __html: html }), [html]);

  if (!html) return null;

  return (
    <div className="card w-full pt-8 pr-12 pb-12 pl-6">
      <div
        className="rich_text columns-2 gap-x-20 font-nunito subpixel-antialiased break-words leading-[1.75]"
        dangerouslySetInnerHTML={dangerousHtml}
      />
    </div>
  );
}
