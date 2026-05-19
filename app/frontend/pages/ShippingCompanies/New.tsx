import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { ShippingCompanyErrors, ShippingCompanyRecord } from "./types";

type NewProps = {
  errors?: ShippingCompanyErrors;
  shippingCompany: ShippingCompanyRecord;
};

export default function New({ errors = {}, shippingCompany }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Shipping Company" />

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
