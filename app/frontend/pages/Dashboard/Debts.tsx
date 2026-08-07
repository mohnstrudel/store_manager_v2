import type { ReactNode } from "react";
import PageHeader from "@/components/PageHeader";
import SearchableTableSection from "@/components/SearchableTableSection";
import { rowNavigationProps } from "@/utils/rowNavigation";
import type { PaginationMeta } from "@/types/pagination";

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
      <PageHeader title="Debts" />

      <div className="section_wide flex flex-col gap-8">
        <SearchableTableSection
          className="table_card"
          hasResults={debts.length > 0}
          pagination={pagination}
          path="/debts"
          query={search.q}
          resourceName="debts"
          showBottomPagination={debts.length > 0}
        >
          <DebtsTable debts={debts} />
        </SearchableTableSection>

        {unpaid_purchases.length > 0 && (
          <UnpaidPurchasesSection unpaidPurchases={unpaid_purchases} />
        )}
      </div>
    </>
  );
}

function DebtsTable({ debts }: { debts: DebtRecord[] }) {
  return (
    <table>
      <thead>
        <tr>
          <th>Title</th>
          <th>Variant</th>
          <th>Sold</th>
          <th>Purchased</th>
          <th>Unit shortfall</th>
        </tr>
      </thead>
      <tbody>
        {debts.map((debt) => (
          <ClickableRow key={`${debt.id}-${debt.row_id}`} path={debt.path}>
            <td>{debt.title}</td>
            <td>{debt.variant_name}</td>
            <td>{debt.sold_amount}</td>
            <td>{debt.purchased_amount}</td>
            <td>{debt.debt}</td>
          </ClickableRow>
        ))}
      </tbody>
    </table>
  );
}

function UnpaidPurchasesSection({ unpaidPurchases }: { unpaidPurchases: UnpaidPurchaseRecord[] }) {
  return (
    <section className="table_card">
      <h3>Purchases Without Payments</h3>
      <table role="grid">
        <thead>
          <tr>
            <th>Purchased Ago</th>
            <th>Supplier</th>
            <th className="text-right">Unit Price</th>
            <th>Qty</th>
          </tr>
        </thead>
        <tbody>
          {unpaidPurchases.map((purchase) => (
            <ClickableRow key={purchase.id} path={purchase.path}>
              <td className="no-wrap">{purchase.purchased_ago}</td>
              <td>{purchase.supplier_title}</td>
              <td className="font-mono text-right">{purchase.item_price}</td>
              <td>{purchase.amount}</td>
            </ClickableRow>
          ))}
        </tbody>
      </table>
    </section>
  );
}

function ClickableRow({ children, path }: { children: ReactNode; path: string }) {
  return (
    <tr className="hoverable" {...rowNavigationProps(path)}>
      {children}
    </tr>
  );
}
