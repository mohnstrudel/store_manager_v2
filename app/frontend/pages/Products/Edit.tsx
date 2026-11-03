import { Link } from "@inertiajs/react";
import { FileTextIcon } from "lucide-react";

import ErrorNotice from "@/components/ErrorNotice";
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

      <PageHeader className="mb-8" title="Edit Product">
        <li>
          <Link href={product.path} prefetch>
            <FileTextIcon />
            View Product
          </Link>
        </li>
      </PageHeader>

      <Form isNew={false} options={options} product={product} submitLabel="Update Product" />
    </>
  );
}
