import type { ReactNode } from "react";

import MetricLabel from "@/components/profitability/MetricLabel";

type FieldProps = {
  children?: ReactNode;
  className?: string;
  label: string;
  value: number | string | null | undefined;
} & ({ anchor?: undefined; hint?: undefined } | { anchor: string; hint: string });

export default function Field({ anchor, children, className, hint, label, value }: FieldProps) {
  if (isBlank(value)) return null;

  return (
    <>
      <dt>
        {hint ? (
          <MetricLabel anchor={anchor} hint={hint}>
            {label}
          </MetricLabel>
        ) : (
          label
        )}
      </dt>
      <dd className={className}>{children ?? value}</dd>
    </>
  );
}

export function isBlank(value: unknown): boolean {
  return value === null || value === undefined || value === "";
}
