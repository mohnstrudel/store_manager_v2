import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import PurchasedSoldRatio from "./PurchasedSoldRatio";
import type { SaleIndexRecord } from "../types";

type TableProps = {
  sales: SaleIndexRecord[];
};

export default function Table({ sales }: TableProps) {
  function visitSale(sale: SaleIndexRecord) {
    router.visit(sale.path);
  }

  function handleKeyDown(sale: SaleIndexRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitSale(sale);
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

  if (sales.length === 0) return null;

  return (
    <div className="table-card">
      <table role="grid">
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
              <tr
                className="hoverable cursor-default"
                key={sale.id}
                onClick={() => visitSale(sale)}
                onKeyDown={(event) => handleKeyDown(sale, event)}
                tabIndex={0}
              >
                <td className="text-center">
                  <div className="flex flex-wrap justify-center gap-2">
                    {sale.sale_items.map((saleItem) =>
                      saleItem.product_thumb_url ? (
                        <div
                          className="preloadable-img__container w-fit h-fit justify-self-center"
                          key={saleItem.id}
                        >
                          <img
                            alt={saleItem.title}
                            className="preloadable-img__img zoomable"
                            src={saleItem.product_thumb_url}
                            style={{ height: "120px", maxWidth: "100px", minWidth: "100px" }}
                          />
                        </div>
                      ) : null
                    )}
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
                          className="mt-2 no-events"
                          href={purchaseItem.path}
                          key={purchaseItem.id}
                          onClick={stopRowNavigation}
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
                      <span className="inline-block icon-woo w-8 h-8 mr-1 -mb-3" />
                      {sale.woo_store_id}
                    </span>
                  )}
                  {(sale.shopify_name || sale.shopify_id_short || sale.shopify_id) && (
                    <span className="block">
                      <span className="inline-block icon-shopify w-5 h-5 mr-1 -mb-1" />
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
    </div>
  );
}
