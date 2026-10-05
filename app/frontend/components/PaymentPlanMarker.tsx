import { Link } from "@inertiajs/react";

import type { SalePaymentPlanRecord, SalePaymentProgress, SettlementStatus } from "@/types/payment";
import { stopRowNavigation } from "@/utils/rowNavigation";

type PaymentPlanMarkerProps = {
  plans?: SalePaymentPlanRecord[];
  progress: SalePaymentProgress | null;
  settlementStatus: SettlementStatus;
};
const EMPTY_PLANS: SalePaymentPlanRecord[] = [];

export default function PaymentPlanMarker({
  plans = EMPTY_PLANS,
  progress,
  settlementStatus,
}: PaymentPlanMarkerProps) {
  if (settlementStatus !== "not_fully_paid") return null;

  const origin = plans.map((plan) => plan.origin_sale).find((sale) => sale != null);

  return (
    <span className="payment_plan_marker">
      <span>{markerText(progress)}</span>
      {origin && (
        <Link className="link" href={origin.path} onClick={stopRowNavigation} prefetch>
          Original sale {origin.identifier}
        </Link>
      )}
    </span>
  );
}

function markerText(progress: SalePaymentProgress | null) {
  switch (progress?.source) {
    case "plan_deposit":
      return `Deposit · ${progress.percent}% collected · Projected total ${progress.total}`;
    case "plan_schedule":
      return `Payment ${progress.sale_part_number} of ${progress.expected_parts} · ${progress.percent}% collected · Projected total ${progress.total}`;
    case "amount":
      return `Not fully paid · ${progress.percent}% collected · Total ${progress.total}`;
    case "woo_deposit":
      return `Not fully paid · Deposit ${progress.paid} collected · Total ${progress.total}`;
    case "woo_unavailable":
      return "Not fully paid · Payment amounts unavailable";
    default:
      return "Not fully paid";
  }
}
