import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { SupplierRecord } from "./types";

type EditProps = {
  supplier: SupplierRecord;
};

export default function Edit({ supplier }: EditProps) {
  return (
    <>
      <PageHeader className="mb-8" title="Edit Supplier">
        <li>
          <Link href={`/suppliers/${supplier.id}`} prefetch>
            <i className="icn">📄</i>
            View Supplier Page
          </Link>
        </li>
      </PageHeader>

      <Form
        method="patch"
        submitLabel="Update Supplier"
        supplier={supplier}
        url={`/suppliers/${supplier.id}`}
      />
    </>
  );
}
