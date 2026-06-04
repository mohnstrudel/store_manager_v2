import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { BrandRecord } from "./types";

type EditProps = {
  brand: BrandRecord;
};

export default function Edit({ brand }: EditProps) {
  return (
    <>
      <PageHeader className="mb-8" title="Edit Brand">
        <li>
          <Link href={`/brands/${brand.id}`} prefetch>
            <i className="icn">📄</i>
            View Brand Page
          </Link>
        </li>
      </PageHeader>
      <Form brand={brand} method="patch" submitLabel="Update Brand" url={`/brands/${brand.id}`} />
    </>
  );
}
