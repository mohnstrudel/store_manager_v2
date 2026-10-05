import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";

import Form from "./components/Form";
import type { SaleFormOptions, SaleFormRecord } from "./types";

type NewProps = {
  options: SaleFormOptions;
  sale: SaleFormRecord;
};

export default function New({ options, sale }: NewProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="New Sale" />

      <Form isNew options={options} sale={sale} submitLabel="Create Sale" />
    </>
  );
}
