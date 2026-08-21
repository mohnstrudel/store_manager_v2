import { Link } from "@inertiajs/react";

import PaymentPlanMarker, { isFollowUpPayment } from "@/components/PaymentPlanMarker";
import ZoomableThumbnail from "@/components/ZoomableThumbnail";

import { SaleRecord } from "../types";

type SalesProps = {
  heading: string;
  sales: SaleRecord[];
};

export default function Sales({ heading, sales }: SalesProps) {
  if (sales.length === 0) return null;

  return (
    <section className="table_card">
      <h3>{heading}</h3>
      <table>
        <thead>
          <tr>
            <th className="text-center">Image</th>
            <th>Sale</th>
            <th>Status</th>
            <th>Price</th>
            <th>Country</th>
            <th>City</th>
            <th>Note</th>
            <th>
              <span className="block">Created</span>
              <span className="font-normal text-gray-500">Updated</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {sales.map((sale) => (
            <tr data-follow-up={isFollowUpPayment(sale.payment_plans) || undefined} key={sale.id}>
              <td className="text-center">
                <ZoomableThumbnail
                  alt={sale.sold_product_name || `${saleNoun(sale)} ${saleIdentifier(sale)}`}
                  key={`${sale.id}-${sale.product_thumb_url ?? "missing"}`}
                  src={sale.product_thumb_url}
                />
              </td>
              <td>
                <Link
                  aria-label={saleLinkLabel(sale)}
                  className="link group no-underline inline-flex items-start gap-2 p-0 bg-transparent hover:bg-transparent"
                  href={sale.path}
                  prefetch
                >
                  {sale.store_type === "shopify" && (
                    <span aria-hidden="true" className="inline-block icon_shopify w-5 h-5 mt-0.5" />
                  )}
                  {sale.store_type === "woo" && (
                    <span aria-hidden="true" className="inline-block icon_woo w-8 h-8 -mt-1" />
                  )}
                  <span className="min-w-0">
                    <span className="block max-w-xl font-semibold leading-tight group-hover:text-blue-600 dark:group-hover:text-blue-400">
                      {sale.sold_product_name || "No sold product"}
                    </span>
                    <span className="mt-1 block font-mono text-sm text-gray-500">
                      {saleIdentifier(sale)}
                    </span>
                  </span>
                </Link>
                <PaymentPlanMarker plans={sale.payment_plans} />
              </td>
              <td>
                <span className={sale.active ? "text-lime-700" : "text-red-900"}>
                  {sale.status
                    .split("-")
                    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
                    .join(" ")}
                </span>
              </td>
              <td className="font-mono whitespace-nowrap">{sale.total ?? ""}</td>
              <td>{sale.country ?? ""}</td>
              <td>{sale.city ?? ""}</td>
              <td>{sale.note ?? ""}</td>
              <td>
                {sale.created_at}
                {sale.updated_at ? (
                  <>
                    <br />
                    <span className="text-gray-500">{sale.updated_at}</span>
                  </>
                ) : null}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

function saleLinkLabel(sale: SaleRecord) {
  return [sale.sold_product_name || "No sold product", saleIdentifier(sale)]
    .filter(Boolean)
    .join(" ");
}

function saleIdentifier(sale: SaleRecord) {
  return String(sale.sale_identifier || sale.store_id || sale.id);
}

function saleNoun(sale: SaleRecord) {
  return sale.is_follow_up_payment ? "Payment" : "Sale";
}
