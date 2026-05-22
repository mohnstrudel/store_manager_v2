import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { type FormOptions, type ProductFormRecord, type PurchaseFormData } from "./types";

type NewProps = {
  options: FormOptions;
  product: ProductFormRecord;
  purchase: PurchaseFormData;
};

export default function New({ options, product, purchase }: NewProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader className="mb-8" title="New Product" />

      <Form
        isNew
        options={options}
        product={product}
        purchase={purchase}
        submitLabel="Create Product"
      />
    </>
  );
}
