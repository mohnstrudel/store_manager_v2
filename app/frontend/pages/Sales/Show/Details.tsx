import { Link } from "@inertiajs/react";
import { useMemo } from "react";

import Field from "@/components/Field";
import PaymentProgressBar from "@/components/PaymentProgressBar";
import PlanProgressBar from "@/components/PlanProgressBar";
import type {
  PaymentPlanPaymentRef,
  PaymentProgress,
  SalePaymentPlanRecord,
  SalePaymentProgress,
  SettlementStatus,
} from "@/types/payment";

import type { SaleShowRecord } from "../types";
import ShippingBillingDetails from "./ShippingBillingDetails";

type DetailsProps = {
  sale: SaleShowRecord;
};

export default function Details({ sale }: DetailsProps) {
  const showOrderOnlyDetails = !sale.is_follow_up_payment;
  const plans = sale.payment_plans;

  return (
    <div className="cards items-start">
      <dl className="card w-2/3">
        {!showOrderOnlyDetails && <OriginSaleField plans={plans} />}
        <Field label="E-Commerce Order Status" value={formatStatus(sale.status)} />
        <Field label="Email" value={sale.customer.email} />
        <Field label="Customer Shop ID" value={sale.customer.shopify_id_short}>
          <a className="link" href={sale.customer.shop_admin_url}>
            {sale.customer.shopify_id_short}
          </a>
        </Field>
        <Field label="Customer" value={sale.customer.full_name}>
          <Link className="link" href={sale.customer.path} prefetch>
            {sale.customer.full_name}
          </Link>
        </Field>
        <Field label="Note" value={sale.note} />
        <Field className="fit font-mono" label="Total" value={sale.total} />
        <Field
          className="fit font-mono"
          label="Projected total"
          value={projectedTotal(sale.payment_plans)}
        />
        {showOrderOnlyDetails && (
          <>
            <Field className="fit font-mono" label="Discount" value={sale.discount_total} />
            <Field className="fit font-mono" label="Shipping" value={sale.shipping_total} />
          </>
        )}
      </dl>

      <div className="flex flex-col gap-4 w-1/3">
        <SettlementSummaryCard sale={sale} />
        {showOrderOnlyDetails && <ShippingBillingDetails sale={sale} />}
      </div>

      <dl className="card">
        <Field label="ID" value={sale.id} />
        <Field label="Shop Created" value={sale.created_at} />
        <Field label="Shop Updated" value={sale.updated_at} />
        <Field label="Order Shop ID" value={sale.shopify_id_short}>
          <a className="link" href={sale.shop_admin_url}>
            {sale.shopify_id_short}
          </a>
        </Field>
      </dl>
    </div>
  );
}

function OriginSaleField({ plans }: { plans: SalePaymentPlanRecord[] }) {
  const origin = plans.map((plan) => plan.origin_sale).find((originSale) => originSale != null);
  if (!origin) return null;

  return (
    <Field label="Original Sale" value={origin.identifier}>
      <Link className="link" href={origin.path} prefetch>
        {origin.identifier}
      </Link>
    </Field>
  );
}

function formatStatus(status: string) {
  return status
    .split("-")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

function projectedTotal(plans: SalePaymentPlanRecord[]): string | null {
  const totals = new Set(
    plans.map((plan) => plan.projected_total).filter((total): total is string => total != null),
  );

  return totals.size === 1 ? [...totals][0] : null;
}

function SettlementSummaryCard({ sale }: { sale: SaleShowRecord }) {
  const status = sale.settlement_status;
  const progress = sale.payment_progress;
  const plans = sale.payment_plans;
  if (status == null && plans.length === 0) return null;

  const lists = planPaymentLists(plans);
  const scheduledPlan = progress?.plan_id
    ? plans.find((plan) => plan.id === progress.plan_id)
    : plans.find((plan) => plan.sale_part_number != null);

  return (
    <section aria-label="Payment status" className="card w-full">
      {status && <h3>{settlementStatusLabel(status)}</h3>}
      {status === "unknown" ? (
        <p>Payment status unknown</p>
      ) : (
        progress &&
        (progress.source !== "plan_schedule" ||
          scheduledPlan?.sale_part_number == null ||
          scheduledPlan.kind === "deposit") && <SettlementProgress progress={progress} />
      )}
      {scheduledPlan && <PlanProgressBar plan={scheduledPlan} />}
      {lists && <div className="mt-4">{lists}</div>}
    </section>
  );
}

function planPaymentLists(plans: SalePaymentPlanRecord[]) {
  const withPayments = plans.filter((plan) => plan.payments.length > 0);
  if (withPayments.length === 0) return null;

  return withPayments.map((plan) => (
    <ul key={plan.id} className="mt-1 first:mt-0">
      {plan.payments.map((payment) => (
        <li key={payment.sequence}>
          {payment.is_current_sale ? (
            <span>{paymentLabel(payment, plan.expected_parts)} (this sale)</span>
          ) : (
            <Link className="link" href={payment.path} prefetch>
              {paymentLabel(payment, plan.expected_parts)}
            </Link>
          )}
        </li>
      ))}
    </ul>
  ));
}

function settlementStatusLabel(status: Exclude<SettlementStatus, null>) {
  switch (status) {
    case "paid":
      return "Paid";
    case "not_fully_paid":
      return "Not fully paid";
    case "unknown":
      return "Unknown";
  }
}

function SettlementProgress({ progress }: { progress: SalePaymentProgress }) {
  const progressProps = useMemo<PaymentProgress | null>(() => {
    if (progress.percent == null) return null;

    return {
      progress: progress.percent,
      paid: progress.paid,
      price: progress.total,
      debt: progress.remaining,
    };
  }, [progress.percent, progress.paid, progress.total, progress.remaining]);
  return (
    <div className="my-3">
      {progressProps && <PaymentProgressBar caption="none" progress={progressProps} />}
      <p className="mt-2">{paymentProgressText(progress)}</p>
    </div>
  );
}

function paymentProgressText(progress: SalePaymentProgress) {
  switch (progress.source) {
    case "plan_schedule":
      return withRemaining(
        `${progress.percent}% · ${progress.completed_parts} of ${progress.expected_parts} payments completed · Paid ${progress.paid} of ${progress.total}`,
        progress,
      );
    case "plan_deposit":
      return withRemaining(
        `${progress.percent}% · Paid ${progress.paid} of projected ${progress.total}`,
        progress,
      );
    case "amount":
      return withRemaining(
        `${progress.percent}% · Paid ${progress.paid} of ${progress.total}`,
        progress,
      );
    case "woo_deposit":
      return `Deposit ${progress.paid} collected of total ${progress.total} · Remaining amount unavailable from WooCommerce`;
    case "woo_unavailable":
      return `Total ${progress.total} · Paid and remaining amounts unavailable from WooCommerce`;
    default:
      return null;
  }
}

function withRemaining(text: string, progress: SalePaymentProgress) {
  if (progress.percent === 100 || progress.remaining == null) return text;

  return `${text} · ${progress.remaining} remaining`;
}
function paymentLabel(payment: PaymentPlanPaymentRef, expectedParts: number) {
  return `Payment ${payment.sequence} of ${expectedParts} · ${payment.identifier}`;
}
