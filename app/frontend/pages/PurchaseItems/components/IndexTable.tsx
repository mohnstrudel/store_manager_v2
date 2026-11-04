import { Link } from "@inertiajs/react";
import { PencilIcon } from "lucide-react";

import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";

import type { PurchaseItemIndexRecord } from "../types";

export type PurchaseItemRecord = PurchaseItemIndexRecord;

type IndexTableProps = {
  purchaseItems: PurchaseItemRecord[];
};

export default function IndexTable({ purchaseItems }: IndexTableProps) {
  return (
    <table>
      <thead>
        <tr>
          <th>Purchase</th>
          <th>Product</th>
          <th>Warehouse</th>
          <th>Sale</th>
          <th>Tracking</th>
          <th>Shipping</th>
          <th>Updated</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {purchaseItems.map((purchaseItem) => (
          <tr
            className="hoverable"
            key={purchaseItem.id}
            {...rowNavigationProps(purchaseItem.path)}
          >
            <td>
              <Link href={purchaseItem.purchase_path} onClick={stopRowNavigation} prefetch>
                {purchaseItem.purchase_title}
              </Link>
            </td>
            <td>
              {purchaseItem.product_path ? (
                <Link href={purchaseItem.product_path} onClick={stopRowNavigation} prefetch>
                  {purchaseItem.product_title}
                </Link>
              ) : (
                purchaseItem.product_title
              )}
              {hasVariantTitle(purchaseItem) ? (
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  {purchaseItem.variant_title}
                </div>
              ) : null}
            </td>
            <td>
              <Link href={purchaseItem.warehouse_path} onClick={stopRowNavigation} prefetch>
                {purchaseItem.warehouse_name}
              </Link>
            </td>
            <td>
              {purchaseItem.sale_path ? (
                <Link href={purchaseItem.sale_path} onClick={stopRowNavigation} prefetch>
                  {purchaseItem.sale_title}
                </Link>
              ) : null}
              {purchaseItem.customer_email && (
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  {purchaseItem.customer_email}
                </div>
              )}
            </td>
            <td>{purchaseItem.tracking_number}</td>
            <td>
              <div>{purchaseItem.shipping_company_name}</div>
              <div className="font-mono text-sm">{purchaseItem.shipping_cost}</div>
            </td>
            <td>{purchaseItem.updated_at}</td>
            <td className="table_actions text-right">
              <Link href={purchaseItem.edit_path} onClick={stopRowNavigation} prefetch>
                <PencilIcon />
                Edit
              </Link>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function hasVariantTitle(purchaseItem: PurchaseItemRecord) {
  return Boolean(purchaseItem.variant_title);
}
