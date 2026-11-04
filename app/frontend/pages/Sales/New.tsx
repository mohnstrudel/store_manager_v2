import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import type { SalesForm } from "@/types/serializers";

import Form from "./components/Form";

type NewProps = SalesForm;

export default function New({ options, sale }: NewProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="New Sale" />

      <Form isNew options={options} sale={sale} submitLabel="Create Sale" />
    </>
  );
}
