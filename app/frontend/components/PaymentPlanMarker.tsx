import { Link } from "@inertiajs/react";

import type { SalePaymentPlanRecord } from "@/types/payment";
import { stopRowNavigation } from "@/utils/rowNavigation";

type PaymentPlanMarkerProps = {
  plans: SalePaymentPlanRecord[];
};

export default function PaymentPlanMarker({ plans }: PaymentPlanMarkerProps) {
  if (plans.length === 0) return null;

  return (
    <span className="payment_plan_marker" data-follow-up={isFollowUpPayment(plans) || undefined}>
      {plans.map((plan) => (
        <PaymentPlanLine key={plan.id} plan={plan} />
      ))}
    </span>
  );
}

export function isFollowUpPayment(plans: SalePaymentPlanRecord[]) {
  return plans.some(isLaterPayment);
}

function PaymentPlanLine({ plan }: { plan: SalePaymentPlanRecord }) {
  return (
    <span className="payment_plan_marker__line">
      <span>{planLabel(plan)}</span>
      {plan.origin_sale ? (
        <Link className="link" href={plan.origin_sale.path} onClick={stopRowNavigation} prefetch>
          Original sale {plan.origin_sale.identifier}
        </Link>
      ) : null}
    </span>
  );
}

function planLabel(plan: SalePaymentPlanRecord) {
  const projection = plan.projected_total ? ` · Projected total ${plan.projected_total}` : "";

  if (plan.kind === "deposit") {
    const state = plan.collected_parts > 0 ? " collected" : "";

    return `${plan.deposit_percent}% deposit${state}${projection}`;
  }

  if (isLaterPayment(plan)) {
    return `Payment ${plan.sale_part_number} of ${plan.expected_parts}${projection}`;
  }

  return `Payment plan · ${plan.collected_parts} of ${plan.expected_parts} collected${projection}`;
}

function isLaterPayment(plan: SalePaymentPlanRecord) {
  return !plan.is_origin_sale && plan.sale_part_number != null;
}
