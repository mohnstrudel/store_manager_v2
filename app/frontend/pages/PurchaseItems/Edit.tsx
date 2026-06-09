import { Link } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import SaleItemsTable from "./components/SaleItemsTable";
import type { PurchaseItemFormOptions, PurchaseItemFormRecord, SaleItemTableRow } from "./types";

type EditProps = {
  options: PurchaseItemFormOptions;
  purchase_item: PurchaseItemFormRecord;
  sale_items_table: SaleItemTableRow[];
};

export default function Edit({ options, purchase_item, sale_items_table }: EditProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title={`Edit Purchase Item ${purchase_item.id}`}>
        <li>
          <Link href={purchase_item.path} prefetch>
            <i className="icn">📦</i>
            View Purchase Item
          </Link>
        </li>
      </PageHeader>

      <SaleItemsTable rows={sale_items_table} />

      <Form
        action={purchase_item.path}
        cancelHref={purchase_item.path}
        method="patch"
        options={options}
        purchase_item={purchase_item}
        submitLabel="Update Purchase Item"
      />
    </>
  );
}
