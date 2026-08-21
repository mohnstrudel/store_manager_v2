import { router, Link } from "@inertiajs/react";
import { useCallback } from "react";
import type { ReactNode } from "react";

import PageHeader from "@/components/PageHeader";
import { rowNavigationProps } from "@/utils/rowNavigation";

type SaleDebtRecord = {
  id: number;
  path: string;
  row_id: number;
  title: string;
  variant_name: string;
  debt: number;
};

type SupplierDebtRecord = {
  supplier_id: number;
  supplier_title: string;
  supplier_path: string;
  total_cost: string;
  total_size: number;
  paid: string;
  total_debt: string;
};

type IndexProps = {
  debts_path: string;
  last_orders_pull_path: string;
  sale_debts: SaleDebtRecord[];
  sale_debts_count: number;
  sales_hook_disabled: boolean;
  suppliers_debts: SupplierDebtRecord[];
  total_suppliers_debt: string;
};

export default function Index({
  debts_path,
  last_orders_pull_path,
  sale_debts,
  sale_debts_count,
  sales_hook_disabled,
  suppliers_debts,
  total_suppliers_debt,
}: IndexProps) {
  return (
    <>
      {sales_hook_disabled && <WebhookWarning lastOrdersPullPath={last_orders_pull_path} />}

      <PageHeader title="Dashboard" />

      <SalesDebtSection debtsPath={debts_path} saleDebts={sale_debts} total={sale_debts_count} />

      {suppliers_debts.length > 0 && (
        <SuppliersDebtSection supplierDebts={suppliers_debts} totalDebt={total_suppliers_debt} />
      )}
    </>
  );
}

function WebhookWarning({ lastOrdersPullPath }: { lastOrdersPullPath: string }) {
  const confirmWebhookActive = useCallback(() => {
    router.post(lastOrdersPullPath);
  }, [lastOrdersPullPath]);

  return (
    <article
      id="webhook-error"
      className="h-fit mx-auto bg-red-100 rounded-xl mb-8 text-center text-red-700 lg:text-left dark:bg-red-800/60 dark:text-red-300"
    >
      <header className="p-0 flex flex-col justify-between items-center gap-2 border-b-4 border-red-800/5 dark:border-red-950/30 lg:p-8 lg:h-24 lg:flex-row lg:gap-0">
        <i className="icn text-2xl lg:text-3xl">🪝</i>
        <p className="text-base font-semibold lg:text-lg">
          The WooCommerce Sales Webhook is Deactivated
        </p>
        <i className="icn text-2xl lg:text-3xl">🪝</i>
      </header>
      <ol className="list-decimal h-fit min-h-24 p-8 pl-16 text-lg">
        <li className="mt-1">
          Change the webhook status to "Active" at{" "}
          <a
            className="link"
            href="https://store.handsomecake.com/wp-admin/admin.php?page=wc-settings&tab=advanced&section=webhooks&edit-webhook=3"
            rel="noopener noreferrer"
            target="_blank"
          >
            the Woo settings page
          </a>
          .
        </li>
        <li className="mt-2">
          Afterward, hide this notification using this button:
          <button
            className="btn_rounded btn_red bg-red-200/60 hover:bg-red-200 dark:bg-red-950 dark:hover:bg-red-900/70 text-sm ml-2"
            onClick={confirmWebhookActive}
            type="button"
          >
            Confirm Woo Webhook Active
          </button>
        </li>
      </ol>
    </article>
  );
}

type SalesDebtSectionProps = {
  debtsPath: string;
  saleDebts: SaleDebtRecord[];
  total: number;
};

function SalesDebtSection({ debtsPath, saleDebts, total }: SalesDebtSectionProps) {
  return (
    <section className="section_border_base section_wide">
      <DashboardSectionTitle label="Products Short" value={total} />
      <table>
        <thead>
          <tr>
            <th>Title</th>
            <th>Variant</th>
            <th>Unit shortfall</th>
          </tr>
        </thead>
        <tbody>
          {saleDebts.map((debt) => (
            <ClickableRow key={`${debt.id}-${debt.row_id}`} path={debt.path}>
              <td>{debt.title}</td>
              <td>{debt.variant_name}</td>
              <td>{debt.debt}</td>
            </ClickableRow>
          ))}
          <tr className="hover:bg-transparent hover:cursor-default">
            <td colSpan={3}>
              <Link href={debtsPath} prefetch>
                See More...
              </Link>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  );
}

type SuppliersDebtSectionProps = {
  supplierDebts: SupplierDebtRecord[];
  totalDebt: string;
};

function SuppliersDebtSection({ supplierDebts, totalDebt }: SuppliersDebtSectionProps) {
  return (
    <section className="section_border_base section_wide">
      <DashboardSectionTitle label="Supplier Debt" value={totalDebt} />
      <table>
        <thead>
          <tr>
            <th>Supplier</th>
            <th className="text-right">Total Cost</th>
            <th>Purchases Qty</th>
            <th className="text-right">Paid</th>
            <th className="text-right">Debt</th>
          </tr>
        </thead>
        <tbody>
          {supplierDebts.map((supplierDebt) => (
            <ClickableRow key={supplierDebt.supplier_id} path={supplierDebt.supplier_path}>
              <td>{supplierDebt.supplier_title}</td>
              <td className="font-mono text-right">{supplierDebt.total_cost}</td>
              <td>{supplierDebt.total_size}</td>
              <td className="font-mono text-right">{supplierDebt.paid}</td>
              <td className="font-mono text-right">{supplierDebt.total_debt}</td>
            </ClickableRow>
          ))}
        </tbody>
      </table>
    </section>
  );
}

function DashboardSectionTitle({ label, value }: { label: string; value: ReactNode }) {
  return (
    <h3 className="flex justify-between px-3 pt-4">
      <span>{label}</span>
      <span>{value}</span>
    </h3>
  );
}

function ClickableRow({ children, path }: { children: ReactNode; path: string }) {
  return (
    <tr className="hoverable" {...rowNavigationProps(path)}>
      {children}
    </tr>
  );
}
