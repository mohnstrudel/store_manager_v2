import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { CustomerErrors, CustomerRecord } from "./types";

type NewProps = {
  customer: CustomerRecord;
  errors?: CustomerErrors;
};

export default function New({ customer, errors = {} }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Customer" />

      <Form
        customer={customer}
        errors={errors}
        method="post"
        submitLabel="Create Customer"
        url="/customers"
      />
    </>
  );
}
