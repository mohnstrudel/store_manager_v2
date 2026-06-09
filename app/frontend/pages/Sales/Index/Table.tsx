import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import ZoomableThumbnail from "@/components/ZoomableThumbnail";
import PurchasedSoldRatio from "../components/PurchasedSoldRatio";
import type { SaleIndexRecord } from "../types";

type TableProps = {
  sales: SaleIndexRecord[];
};

export default function Table({ sales }: TableProps) {
  if (sales.length === 0) return null;

  return (
    <table>
      <thead>
        <tr>
          <th className="text-center">Image</th>
          <th>
            <span>Customer</span> <span className="font-normal text-sm pl-4">+ Products</span>
          </th>
          <th className="w-80">Purchase Status</th>
          <th className="text-right">Price</th>
          <th>
            Created&nbsp;&nbsp;▾
            <br />
            <span className="font-normal text-gray-500">Updated</span>
          </th>
          <th>Store ID</th>
        </tr>
      </thead>
      <tbody>
        {sales.map((sale) => {
          const purchaseItems = sale.sale_items.flatMap((saleItem) => saleItem.purchase_items);

          return (
            <tr className="hoverable" key={sale.id} {...rowNavigationProps(sale.path)}>
              <td className="text-center">
                <div className="flex flex-wrap justify-center gap-2">
                  {sale.sale_items.map((saleItem) => (
                    <ZoomableThumbnail
                      alt={saleItem.title}
                      key={`${saleItem.id}-${saleItem.product_thumb_url ?? "missing"}`}
                      src={saleItem.product_thumb_url}
                    />
                  ))}
                </div>
              </td>

              <td>
                <span className="font-bold">{sale.customer_name}</span>
                {sale.customer_email ? (
                  <>
                    <br />
                    {sale.customer_email}
                  </>
                ) : null}
                <ul className="mt-2">
                  {sale.sale_items.map((saleItem) => (
                    <li key={saleItem.id}>
                      {sale.active || sale.completed ? (
                        <PurchasedSoldRatio
                          purchased={saleItem.purchased_count}
                          sold={saleItem.qty}
                        />
                      ) : null}
                      {saleItem.title}
                    </li>
                  ))}
                </ul>
              </td>

              <td className="text-sm">
                {purchaseItems.length > 0 ? (
                  <div className="flex flex-col items-start gap-2">
                    {purchaseItems.map((purchaseItem) => (
                      <Link
                        className="mt-2 no_events"
                        href={purchaseItem.path}
                        key={purchaseItem.id}
                        onClick={stopRowNavigation}
                        prefetch
                      >
                        <i className="icn">📦</i>
                        {purchaseItem.warehouse_name}
                        {purchaseItem.expenses != null && (
                          <>
                            {" "}
                            — expenses: $
                            <span className="font-mono inline">{purchaseItem.expenses}</span>
                          </>
                        )}
                      </Link>
                    ))}
                  </div>
                ) : null}
              </td>

              <td className="text-right font-mono whitespace-nowrap">{sale.total ?? ""}</td>

              <td>
                {sale.created_at}
                {sale.updated_at ? (
                  <>
                    <br />
                    <span className="text-gray-500">{sale.updated_at}</span>
                  </>
                ) : null}
              </td>

              <td>
                {sale.woo_store_id && (
                  <span className="block">
                    <span className="inline-block icon_woo w-8 h-8 mr-1 -mb-3" />
                    {sale.woo_store_id}
                  </span>
                )}
                {(sale.shopify_name || sale.shopify_id_short || sale.shopify_id) && (
                  <span className="block">
                    <span className="inline-block icon_shopify w-5 h-5 mr-1 -mb-1" />
                    {sale.shopify_name || sale.shopify_id_short || sale.shopify_id}
                    {sale.shopify_id_short && (
                      <>
                        <br />
                        <span className="text-gray-500">{sale.shopify_id_short}</span>
                      </>
                    )}
                  </span>
                )}
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
