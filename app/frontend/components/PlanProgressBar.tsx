import type { SalePaymentPlanRecord } from "@/types/payment";

type PlanProgressBarProps = {
  plan: SalePaymentPlanRecord;
};

export default function PlanProgressBar({ plan }: PlanProgressBarProps) {
  if (plan.sale_part_number == null) return null;

  const segments = Array.from({ length: plan.expected_parts }, (_, index) => index + 1);
  const currentPart = plan.sale_part_number;

  return (
    <div className="plan_progress_bar">
      <div className="plan_progress_bar__track">
        {segments.map((segment) => (
          <span
            key={segment}
            className="plan_progress_bar__segment"
            data-current={segment === currentPart || undefined}
            data-filled={segment <= plan.collected_parts || undefined}
          >
            {segment === currentPart && <span className="sr-only">This payment</span>}
          </span>
        ))}
      </div>
      <p className="plan_progress_bar__caption">{captionFor(plan, currentPart)}</p>
    </div>
  );
}

function captionFor(plan: SalePaymentPlanRecord, currentPart: number) {
  const position = `Payment ${currentPart} of ${plan.expected_parts}`;

  if (!plan.projected_total) return position;

  return `${position} · ${collectedLabel(plan)} of ${plan.projected_total} collected`;
}

function collectedLabel(plan: SalePaymentPlanRecord) {
  return plan.projected_collected || "n/p";
}
