import { Link } from "@inertiajs/react";

import TipMark from "@/components/TipMark";

type MetricLabelProps = {
  // Id of the term's entry on the glossary page (`app/frontend/pages/Glossary/Show.tsx`).
  // Every hint links there so "what does this number mean" has one answer in one place.
  anchor: string;
  children: string;
  hint: string;
  // The default treatment hangs a small "*" mark after the label as the
  // only hover/focus target. Setting this makes the label's own text that
  // target and drops the mark, for contexts where the label is the whole
  // visible affordance.
  hoverWhole?: boolean;
};

export default function MetricLabel({
  anchor,
  children,
  hint,
  hoverWhole = false,
}: MetricLabelProps) {
  const tip = (
    <>
      <span className="tip_mark__hint">{hint}</span>
      <Link className="tip_mark__glossary_link link" href={`/glossary#${anchor}`}>
        Glossary
      </Link>
    </>
  );

  if (hoverWhole) {
    return (
      <TipMark trigger={children} triggerClassName="metric_label metric_label--hoverable">
        {tip}
      </TipMark>
    );
  }

  return (
    <span className="metric_label">
      {children}
      <span aria-hidden="true">
        <TipMark>{tip}</TipMark>
      </span>
    </span>
  );
}
