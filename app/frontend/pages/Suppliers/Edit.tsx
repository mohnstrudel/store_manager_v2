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
      <PageHeader
        actions={
          <li>
            <Link href={`/suppliers/${supplier.id}`} prefetch>
              <i className="icn">📄</i>
              View Supplier Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Supplier"
      />

      <Form
        method="patch"
        submitLabel="Update Supplier"
        supplier={supplier}
        url={`/suppliers/${supplier.id}`}
      />
    </>
  );
}
