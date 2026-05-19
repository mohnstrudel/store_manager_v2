import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { CustomerErrors, CustomerRecord } from "./types";

type EditProps = {
  customer: CustomerRecord;
  errors?: CustomerErrors;
};

export default function Edit({ customer, errors = {} }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader
        actions={
          <li>
            <Link href={`/customers/${customer.id}`}>
              <i className="icn">📄</i>
              View Customer Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Customer"
      />

      <Form
        customer={customer}
        errors={errors}
        method="patch"
        submitLabel="Update Customer"
        url={`/customers/${customer.id}`}
      />
    </>
  );
}
