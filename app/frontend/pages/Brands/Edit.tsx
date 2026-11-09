import { Link } from "@inertiajs/react";
import { FileTextIcon } from "lucide-react";

import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import Form from "./components/Form";
import { BrandRecord } from "./types";

type EditProps = {
  brand: BrandRecord;
};

export default function Edit({ brand }: EditProps) {
  const currentBrandPath = routes.brands.show.path({ id: brand.id });

  return (
    <>
      <PageHeader className="mb-8" title="Edit Brand">
        <li>
          <Link href={currentBrandPath} prefetch>
            <FileTextIcon />
            View Brand Page
          </Link>
        </li>
      </PageHeader>
      <Form brand={brand} method="patch" submitLabel="Update Brand" url={currentBrandPath} />
    </>
  );
}
