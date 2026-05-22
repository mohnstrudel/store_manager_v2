import ErrorNotice from "@/components/ErrorNotice";
import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { type FormOptions, type ProductFormRecord } from "./types";

type EditProps = {
  options: FormOptions;
  product: ProductFormRecord;
};

export default function Edit({ options, product }: EditProps) {
  return (
    <>
      <ErrorNotice />

      <PageHeader
        actions={
          <li>
            <Link href={product.path} prefetch>
              <i className="icn">📄</i>
              View Product
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Product"
      />

      <Form isNew={false} options={options} product={product} submitLabel="Update Product" />
    </>
  );
}
