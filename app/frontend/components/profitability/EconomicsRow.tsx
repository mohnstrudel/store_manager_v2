import { Fragment } from "react";

import Amount, { isNegativeAmount } from "@/components/Amount";
import { isBlank } from "@/components/Field";

import MetricLabel from "./MetricLabel";

export type EconomicsTerm = {
  anchor: string;
  hint: string;
  label: string;
  result?: boolean;
  value: string | null;
};

export default function EconomicsRow({
  groups,
  hoverWholeLabels = false,
}: {
  groups: EconomicsTerm[][];
  hoverWholeLabels?: boolean;
}) {
  const stated = groups.map(statedTerms).filter((terms) => terms.length > 0);

  if (stated.length === 0) return null;

  return (
    <div className="economics_snapshot__equation">
      {stated.map((terms, index) => (
        <Fragment key={terms[0].anchor}>
          {index > 0 && <span aria-hidden="true" className="economics_snapshot__divider" />}
          <div className="economics_snapshot__group">
            {terms.map((term) => (
              <Term
                anchor={term.anchor}
                hint={term.hint}
                hoverWhole={hoverWholeLabels}
                key={term.anchor}
                label={term.label}
                result={term.result}
                value={term.value}
              />
            ))}
          </div>
        </Fragment>
      ))}
    </div>
  );
}

function statedTerms(group: EconomicsTerm[]): EconomicsTerm[] {
  return group.filter((term) => !isBlank(term.value));
}

function Term({
  anchor,
  hint,
  hoverWhole,
  label,
  result = false,
  value,
}: EconomicsTerm & { hoverWhole: boolean }) {
  return (
    <div className={result ? RESULT_TERM_CLASS : TERM_CLASS} data-testid={`metric-${anchor}`}>
      <span className="economics_snapshot__value">
        {result ? <Amount emphasizeSign value={value} /> : value}
      </span>
      <span
        className="economics_snapshot__label"
        data-tone={result ? profitTone(value) : undefined}
      >
        <MetricLabel anchor={anchor} hint={hint} hoverWhole={hoverWhole}>
          {label}
        </MetricLabel>
      </span>
    </div>
  );
}

const TERM_CLASS = "economics_snapshot__term";
const RESULT_TERM_CLASS = "economics_snapshot__term economics_snapshot__term--result";

function profitTone(value: string | null): "negative" | "positive" | undefined {
  if (value === null) return undefined;

  return isNegativeAmount(value) ? "negative" : "positive";
}
