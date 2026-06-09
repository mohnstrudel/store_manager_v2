import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { type PurchaseFormOptions, type PurchaseFormRecord } from "./types";

type NewProps = {
  options: PurchaseFormOptions;
  purchase: PurchaseFormRecord;
};

export default function New({ options, purchase }: NewProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="New Purchase" />

      <Form isNew options={options} purchase={purchase} submitLabel="Create Purchase" />
    </>
  );
}
