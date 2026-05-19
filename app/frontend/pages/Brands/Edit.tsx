import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { BrandErrors, BrandRecord } from "./types";

type EditProps = {
  brand: BrandRecord;
  errors?: BrandErrors;
};

export default function Edit({ brand, errors = {} }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader
        actions={
          <li>
            <Link href={`/brands/${brand.id}`}>
              <i className="icn">📄</i>
              View Brand Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Brand"
      />

      <Form
        brand={brand}
        errors={errors}
        method="patch"
        submitLabel="Update Brand"
        url={`/brands/${brand.id}`}
      />
    </>
  );
}
