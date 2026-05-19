import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { ShippingCompanyErrors, ShippingCompanyRecord } from "./types";

type EditProps = {
  errors?: ShippingCompanyErrors;
  shippingCompany: ShippingCompanyRecord;
};

export default function Edit({ errors = {}, shippingCompany }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader
        actions={
          <li>
            <Link href={`/shipping_companies/${shippingCompany.id}`}>
              <i className="icn">📄</i>
              View Shipping Company Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Shipping Company"
      />

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
