import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import type { PaginationMeta } from "@/pages/Purchases/types";

type PurchaseItemRecord = {
  id: number;
  path: string;
  edit_path: string;
  purchase_path: string;
  purchase_title: string;
  product_path: string;
  product_title: string;
  variant_title: string;
  warehouse_name: string;
  warehouse_path: string;
  sale_path: string | null;
  sale_title: string;
  customer_email: string;
  tracking_number: string;
  shipping_company_name: string;
  shipping_cost: string;
  updated_at: string;
};

type IndexProps = {
  pagination: PaginationMeta;
  purchase_items: PurchaseItemRecord[];
  search: { q: string };
};

export default function Index({ pagination, purchase_items, search }: IndexProps) {
  return (
    <>
      <header className="nav_header">
        <hgroup>
          <h1>Purchase Items</h1>
        </hgroup>
      </header>

      <section className="section_border_base section_wide">
        <div className="search">
          <SearchBar initialQuery={search.q} path="/purchase_items" resourceName="purchase_items" />
          <div className="pagination_top">
            <Pagination pagination={pagination} path="/purchase_items" query={search.q} />
          </div>
        </div>

        {purchase_items.length > 0 ? (
          <>
            <table role="grid">
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
                {purchase_items.map((purchaseItem) => (
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
                      <Link href={purchaseItem.product_path} onClick={stopRowNavigation} prefetch>
                        {purchaseItem.product_title}
                      </Link>
                      {purchaseItem.variant_title && purchaseItem.variant_title !== "-" && (
                        <div className="text-sm text-gray-500 dark:text-gray-400">
                          {purchaseItem.variant_title}
                        </div>
                      )}
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
                      ) : (
                        "-"
                      )}
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
                    <td className="actions text-right">
                      <Link href={purchaseItem.edit_path} onClick={stopRowNavigation} prefetch>
                        <i className="icn">✏</i>
                        Edit
                      </Link>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="pagination_bottom">
              <Pagination pagination={pagination} path="/purchase_items" query={search.q} />
            </div>
          </>
        ) : search.q ? (
          <SearchResultsEmpty seed={search.q} />
        ) : null}
      </section>
    </>
  );
}
