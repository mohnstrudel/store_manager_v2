import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import Form from "./components/Form";
import { ShippingCompanyErrors, ShippingCompanyRecord } from "./types";

type EditProps = {
  errors: ShippingCompanyErrors;
  shippingCompany: ShippingCompanyRecord;
};

export default function Edit({ errors, shippingCompany }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>Edit Shipping Company</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/shipping_companies/${shippingCompany.id}`}>
              <i className="icn">📄</i>
              View Shipping Company Page
            </Link>
          </li>
        </menu>
      </header>

      <Form
        errors={errors}
        method="patch"
        shippingCompany={shippingCompany}
        submitLabel="Update Shipping Company"
        url={`/shipping_companies/${shippingCompany.id}`}
      />
    </>
  );
}
