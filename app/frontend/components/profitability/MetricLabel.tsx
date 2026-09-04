import { Link } from "@inertiajs/react";

import TipMark from "@/components/TipMark";

type MetricLabelProps = {
  anchor: string;
  children: string;
  hint: string;
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
