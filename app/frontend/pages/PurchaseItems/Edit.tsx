import { Link } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import type { PurchaseItemFormOptions, PurchaseItemFormRecord } from "./types";

type EditProps = {
  options: PurchaseItemFormOptions;
  purchase_item: PurchaseItemFormRecord;
};

export default function Edit({ options, purchase_item }: EditProps) {
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
