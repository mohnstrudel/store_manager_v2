import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { SupplierErrors, SupplierRecord } from "./types";

type EditProps = {
  errors?: SupplierErrors;
  supplier: SupplierRecord;
};

export default function Edit({ errors = {}, supplier }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader
        actions={
          <li>
            <Link href={`/suppliers/${supplier.id}`}>
              <i className="icn">📄</i>
              View Supplier Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Supplier"
      />

      <Form
        errors={errors}
        method="patch"
        submitLabel="Update Supplier"
        supplier={supplier}
        url={`/suppliers/${supplier.id}`}
      />
    </>
  );
}
