import ErrorNotice from "@/components/ErrorNotice";
import Form from "./components/Form";
import { ShippingCompanyErrors, ShippingCompanyRecord } from "./types";

type NewProps = {
  errors: ShippingCompanyErrors;
  shippingCompany: ShippingCompanyRecord;
};

export default function New({ errors, shippingCompany }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>New Shipping Company</h1>
        </div>
      </header>

      <Form
        errors={errors}
        method="post"
        shippingCompany={shippingCompany}
        submitLabel="Create Shipping Company"
        url="/shipping_companies"
      />
    </>
  );
}
