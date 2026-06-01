import { Link } from "@inertiajs/react";
import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import type { PurchaseItemFormOptions, PurchaseItemFormRecord } from "./types";

type NewProps = {
  cancel_path: string;
  form_action: string;
  options: PurchaseItemFormOptions;
  purchase_item: PurchaseItemFormRecord;
};

export default function New({ cancel_path, form_action, options, purchase_item }: NewProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="New Purchase Item">
        <li>
          <Link href={cancel_path} prefetch>
            <i className="icn">🏭</i>
            Back to Warehouse
          </Link>
        </li>
      </PageHeader>

      <Form
        action={form_action}
        cancelHref={cancel_path}
        method="post"
        options={options}
        purchase_item={purchase_item}
        submitLabel="Create Purchase Item"
      />
    </>
  );
}
