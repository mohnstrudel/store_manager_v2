import type { MouseEvent } from "react";
import { Link } from "@inertiajs/react";
import { rowNavigationProps } from "@/lib/rowNavigation";
import { type SaleItemRecord } from "../types";

type SalesSectionProps = {
  hasVariants: boolean;
  sales: SaleItemRecord[];
  title: string;
};

function stopRowNavigation(event: MouseEvent) {
  event.stopPropagation();
}

export default function SalesSection({ hasVariants, sales, title }: SalesSectionProps) {
  if (sales.length === 0) return null;

  return (
    <div className="table-card">
      <h3 className="flex justify-between">
        <span>{title}</span>
        <span>{sales.length}</span>
      </h3>
      <table>
        <thead>
          <tr>
            <th>Shop ID</th>
            <th>
              Customer <span className="font-normal text-sm pl-4">+ Email, Country</span>
            </th>
            <th>Date</th>
            {hasVariants && <th>Variant?</th>}
            <th className="text-right">Price, $</th>
            <th>Amount</th>
            <th>
              Status <span className="font-normal text-sm pl-4">+ Warehouse</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {sales.map((item) => (
            <tr className="hoverable" key={item.id} {...rowNavigationProps(item.sale_path)}>
              <td>
                {item.store_type === "shopify" && (
                  <span className="inline-block icon-shopify w-5 h-5 mr-1" />
                )}
                {item.store_type === "woo" && (
                  <span className="inline-block icon-woo w-8 h-8 mr-2" />
                )}
                {item.store_id ?? ""}
              </td>
              <td>
                <strong>{item.customer_name}</strong>
                <br />
                {item.customer_email}
                <br />
                {item.country}
              </td>
              <td>{item.date}</td>
              {hasVariants && <td>{item.variant_title ?? ""}</td>}
              <td className="text-right font-mono">{item.price}</td>
              <td>{item.qty}</td>
              <td>
                {item.status.charAt(0).toUpperCase() + item.status.slice(1)}
                {item.purchase_item_path && (
                  <div className="mt-1">
                    <Link
                      className="no-events btn-rounded text-xs"
                      href={item.purchase_item_path}
                      onClick={stopRowNavigation}
                    >
                      <i className="icn">📦</i>
                      {item.warehouse || "Purchase Item"}
                    </Link>
                  </div>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
