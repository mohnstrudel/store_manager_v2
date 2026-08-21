import { useMemo } from "react";

import type { PaymentProgress } from "@/types/payment";

type PaymentProgressBarProps = {
  caption?: "full" | "debtOnly" | "paidOfTotal";
  progress: PaymentProgress;
};

export default function PaymentProgressBar({
  caption = "full",
  progress,
}: PaymentProgressBarProps) {
  const percentage = Math.round(progress.progress);

  const progressStyle = useMemo(() => ({ width: `${progress.progress}%` }), [progress.progress]);

  return (
    <>
      <div
        className={`progress_container relative z-10 ${progress.progress >= 100 ? "" : "bg-slate-200/50 dark:bg-slate-700/40"}`}
      >
        {progress.progress > 0 && progress.progress <= 100 && (
          <div className="rounded-full h-full bg-lime-700/80" style={progressStyle}>
            <p className="progress_amount">{percentage}%</p>
          </div>
        )}
      </div>
      {caption === "debtOnly" && progress.progress < 100 && progress.debt && (
        <div className="pt-1 text-sm font-semibold px-2 text-center">
          <span className="text-amber-700/60 dark:text-orange-400/80">{progress.debt} debt</span>
        </div>
      )}
      {caption === "paidOfTotal" && progress.progress < 100 && (
        <div className="pt-1 text-sm font-semibold px-2 text-center">
          <span className="text-lime-700/70 dark:text-lime-500/85">{paidOfTotal(progress)}</span>
        </div>
      )}
      {caption === "full" && progress.progress >= 0 && progress.progress !== 100 && (
        <div className="flex justify-between pt-1 text-sm font-semibold px-2">
          <span className="text-lime-700/70 dark:text-lime-500/85">{paidLabel(progress)}</span>
          <span className="text-gray-400/90">{progress.price}</span>
          <span className="text-amber-700/60 dark:text-orange-400/80">{debtLabel(progress)}</span>
        </div>
      )}
    </>
  );
}

const UNKNOWN_AMOUNT = "unknown";

function paidLabel(progress: PaymentProgress) {
  if (progress.amounts_unknown) return UNKNOWN_AMOUNT;

  return progress.paid || "n/p";
}

function debtLabel(progress: PaymentProgress) {
  if (progress.amounts_unknown) return UNKNOWN_AMOUNT;

  return progress.debt;
}

function paidOfTotal(progress: PaymentProgress) {
  if (!progress.price) return paidLabel(progress);

  return `${paidLabel(progress)} of ${progress.price}`;
}
