import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import Form from "./components/Form";
import { SupplierErrors, SupplierRecord } from "./types";

type EditProps = {
  errors: SupplierErrors;
  supplier: SupplierRecord;
};

export default function Edit({ errors, supplier }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>Edit Supplier</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/suppliers/${supplier.id}`}>
              <i className="icn">📄</i>
              View Supplier Page
            </Link>
          </li>
        </menu>
      </header>

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
