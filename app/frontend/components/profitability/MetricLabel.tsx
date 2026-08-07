import { Link } from "@inertiajs/react";
import TipMark from "@/components/TipMark";

type MetricLabelProps = {
  // Id of the term's entry on the glossary page (`app/frontend/pages/Glossary/Show.tsx`).
  // Every hint links there so "what does this number mean" has one answer in one place.
  anchor: string;
  children: string;
  hint: string;
};

export default function MetricLabel({ anchor, children, hint }: MetricLabelProps) {
  return (
    <span className="metric_label">
      {children}
      <span aria-hidden="true">
        <TipMark>
          <span className="tip_mark__hint">{hint}</span>
          <Link className="tip_mark__glossary_link link" href={`/glossary#${anchor}`}>
            Glossary
          </Link>
        </TipMark>
      </span>
    </span>
  );
}
