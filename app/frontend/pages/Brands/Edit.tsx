import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import Form from "./components/Form";
import { BrandErrors, BrandRecord } from "./types";

type EditProps = {
  brand: BrandRecord;
  errors: BrandErrors;
};

export default function Edit({ brand, errors }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>Edit Brand</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/brands/${brand.id}`}>
              <i className="icn">📄</i>
              View Brand Page
            </Link>
          </li>
        </menu>
      </header>

      <Form brand={brand} errors={errors} method="patch" submitLabel="Update Brand" url={`/brands/${brand.id}`} />
    </>
  );
}
