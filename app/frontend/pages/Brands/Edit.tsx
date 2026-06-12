import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import Form from "./components/Form";
import { BrandRecord } from "./types";

type EditProps = {
  brand: BrandRecord;
};

export default function Edit({ brand }: EditProps) {
  const currentBrandPath =
    brand.id === null ? routes.brands.index.path() : routes.brands.show.path({ id: brand.id });

  return (
    <>
      <PageHeader className="mb-8" title="Edit Brand">
        <li>
          <Link href={currentBrandPath} prefetch>
            <i className="icn">📄</i>
            View Brand Page
          </Link>
        </li>
      </PageHeader>
      <Form brand={brand} method="patch" submitLabel="Update Brand" url={currentBrandPath} />
    </>
  );
}
