import { useMemo } from "react";
import type { PaymentProgress } from "@/types/payment";

type PaymentProgressBarProps = {
  onlyDebt?: boolean;
  progress: PaymentProgress;
};

export default function PaymentProgressBar({
  onlyDebt = false,
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
      {onlyDebt
        ? progress.progress < 100 && (
            <div className="pt-1 text-sm font-semibold px-2 text-center">
              <span className="text-amber-700/60 dark:text-orange-400/80">
                ${progress.debt} debt
              </span>
            </div>
          )
        : progress.progress >= 0 &&
          progress.progress !== 100 && (
            <div className="flex justify-between pt-1 text-sm font-semibold px-2">
              <span className="text-lime-700/70 dark:text-lime-500/85">
                {progress.paid ? progress.paid : "n/p"}
              </span>
              <span className="text-gray-400/90">{progress.price}</span>
              <span className="text-amber-700/60 dark:text-orange-400/80">{progress.debt}</span>
            </div>
          )}
    </>
  );
}
