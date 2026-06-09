import ErrorNotice from "@/components/ErrorNotice";
import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { type PurchaseFormOptions, type PurchaseFormRecord } from "./types";

type EditProps = {
  options: PurchaseFormOptions;
  purchase: PurchaseFormRecord;
};

export default function Edit({ options, purchase }: EditProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="Edit Purchase">
        <li>
          <Link href={purchase.path} prefetch>
            <i className="icn">📄</i>
            View Purchase Page
          </Link>
        </li>
      </PageHeader>

      <Form isNew={false} options={options} purchase={purchase} submitLabel="Update Purchase" />
    </>
  );
}
