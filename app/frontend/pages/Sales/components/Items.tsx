import { router, Link } from "@inertiajs/react";
import { ChevronLeftIcon } from "@heroicons/react/20/solid";
import PurchasedSoldRatio from "./PurchasedSoldRatio";
import type { SaleShowSaleItemRecord } from "../types";

type ItemsProps = {
  saleItems: SaleShowSaleItemRecord[];
};

export default function Items({ saleItems }: ItemsProps) {
  if (saleItems.length === 0) return null;

  return (
    <div className="table-card full-width">
      <table>
        <thead>
          <tr>
            <th className="text-center">Image</th>
            <th>Product</th>
            <th className="text-right">Price, $</th>
            <th className="text-center">Purchased / Sold</th>
          </tr>
        </thead>
        <tbody>
          {saleItems.map((saleItem) => (
            <tr className="cursor-default" key={saleItem.id}>
              <td>
                {saleItem.product_thumb_url ? (
                  <div className="preloadable-img__container w-fit h-fit justify-self-center">
                    <img
                      alt={saleItem.title}
                      className="preloadable-img__img zoomable"
                      src={saleItem.product_thumb_url}
                      style={{ height: "120px", maxWidth: "100px", minWidth: "100px" }}
                    />
                  </div>
                ) : null}
              </td>
              <td>
                <Link className="link no-underline font-semibold" href={saleItem.product_path}>
                  {saleItem.title}
                </Link>
                {saleItem.purchase_items.length > 0 ? (
                  <PurchaseItems purchaseItems={saleItem.purchase_items} />
                ) : (
                  <mark className="block uppercase tracking-wide text-xs w-fit mt-2 -ml-1">
                    <span className="font-semibold">NO PURCHASE</span>
                  </mark>
                )}
              </td>
              <td className="text-right font-mono">{saleItem.price ?? ""}</td>
              <td className="text-center">
                <PurchasedSoldRatio
                  purchased={saleItem.purchase_items.length}
                  sold={saleItem.qty}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function PurchaseItems({
  purchaseItems,
}: {
  purchaseItems: SaleShowSaleItemRecord["purchase_items"];
}) {
  return (
    <menu>
      {purchaseItems.map((purchaseItem) => (
        <li className="mt-4" key={purchaseItem.id}>
          <div className="w-fit flex items-center gap-2">
            <div>
              <span className="text-gray-500">
                <i className="icn">💰</i>&nbsp;Purchase:
              </span>
              <Link className="link ml-2" href={purchaseItem.path}>
                {purchaseItem.supplier_title}, {purchaseItem.purchase_date}
                {purchaseItem.item_price && (
                  <>
                    {", $"}
                    {purchaseItem.item_price}
                  </>
                )}
              </Link>
            </div>

            <button
              className="btn-xs btn-red btn-rounded"
              onClick={() => {
                if (window.confirm("Are you sure?")) {
                  router.delete(purchaseItem.unlink_path);
                }
              }}
              type="button"
            >
              <i className="icn">✂︎</i>
              Unlink
            </button>
          </div>

          {purchaseItem.warehouse_movements.length > 0 && (
            <details className="my-2 group">
              <summary
                className={[
                  "w-fit flex items-center gap-2",
                  purchaseItem.warehouse_movements.length === 1
                    ? "cursor-default"
                    : "cursor-pointer",
                ]
                  .filter(Boolean)
                  .join(" ")}
              >
                <span>
                  <span className="text-gray-500">
                    <i className="icn">📦</i>&nbsp;Status:
                  </span>
                  <Link className="link ml-2" href={purchaseItem.current_warehouse_path}>
                    {purchaseItem.current_warehouse_name}
                  </Link>
                </span>

                {purchaseItem.warehouse_movements.length > 1 && (
                  <span className="text-xs btn-rounded w-5 h-5 p-0 btn-lightblue flex items-center justify-center transition-transform origin-center group-open:-rotate-90">
                    <ChevronLeftIcon className="h-4 w-4" />
                  </span>
                )}
              </summary>

              {purchaseItem.warehouse_movements.length > 1 && (
                <div className="border max-w-2/3 border-gray-100 dark:border-gray-600/40 rounded-sm my-3">
                  <table className="text-sm my-0">
                    <thead>
                      <tr className="cursor-auto">
                        <th>Moved in</th>
                        <th>Warehouse</th>
                      </tr>
                    </thead>
                    <tbody>
                      {purchaseItem.warehouse_movements.slice(1).map((movement, index) => (
                        <tr className="cursor-auto" key={`${purchaseItem.id}-${index}`}>
                          <td className="pr-2 text-muted whitespace-nowrap">{movement.moved_in}</td>
                          <td>{movement.warehouse_name}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </details>
          )}
        </li>
      ))}
    </menu>
  );
}
