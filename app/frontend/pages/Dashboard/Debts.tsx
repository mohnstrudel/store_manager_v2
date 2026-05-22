import { rowNavigationProps } from "@/lib/rowNavigation";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import type { PaginationMeta } from "@/pages/Purchases/types";

type DebtRecord = {
  id: number;
  path: string;
  row_id: number;
  title: string;
  variant_name: string;
  sold_amount: number;
  purchased_amount: number;
  debt: number;
};

type UnpaidPurchaseRecord = {
  id: number;
  path: string;
  purchased_ago: string;
  supplier_title: string;
  item_price: string;
  amount: number;
};

type DebtsProps = {
  debts: DebtRecord[];
  pagination: PaginationMeta;
  search: { q: string };
  unpaid_purchases: UnpaidPurchaseRecord[];
};

export default function Debts({ debts, pagination, search, unpaid_purchases }: DebtsProps) {
  return (
    <>
      <header>
        <h1>Debts</h1>
      </header>

      <div className="section-wide flex flex-col gap-8">
        <div className="table-card">
          <div className="search">
            <SearchBar
              initialQuery={search.q}
              path="/debts"
              reloadOnly={["debts", "pagination", "search"]}
            />
            <div className="pagination-top">
              <Pagination pagination={pagination} params={{ q: search.q }} path="/debts" />
            </div>
          </div>
          {debts.length > 0 ? (
            <>
              <table>
                <thead>
                  <tr>
                    <th>Title</th>
                    <th>Variant</th>
                    <th>Sold</th>
                    <th>Purchased</th>
                    <th>Debt</th>
                  </tr>
                </thead>
                <tbody>
                  {debts.map((debt) => (
                    <tr
                      className="hoverable"
                      key={`${debt.id}-${debt.row_id}`}
                      {...rowNavigationProps(debt.path)}
                    >
                      <td>{debt.title}</td>
                      <td>{debt.variant_name}</td>
                      <td>{debt.sold_amount}</td>
                      <td>{debt.purchased_amount}</td>
                      <td>{debt.debt}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="pagination-bottom">
                <Pagination pagination={pagination} params={{ q: search.q }} path="/debts" />
              </div>
            </>
          ) : search.q ? (
            <SearchResultsEmpty seed={search.q} />
          ) : null}
        </div>

        {unpaid_purchases.length > 0 && (
          <div className="table-card">
            <h3>Purchases Without Payments</h3>
            <table role="grid">
              <thead>
                <tr>
                  <th>Purchased Ago</th>
                  <th>Supplier</th>
                  <th className="text-right">Cost</th>
                  <th>Qty</th>
                </tr>
              </thead>
              <tbody>
                {unpaid_purchases.map((purchase) => (
                  <tr
                    className="hoverable"
                    key={purchase.id}
                    {...rowNavigationProps(purchase.path)}
                  >
                    <td className="no-wrap">{purchase.purchased_ago}</td>
                    <td>{purchase.supplier_title}</td>
                    <td className="font-mono text-right">{purchase.item_price}</td>
                    <td>{purchase.amount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </>
  );
}
