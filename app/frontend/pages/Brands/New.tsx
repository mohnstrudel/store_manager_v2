import ErrorNotice from "@/components/ErrorNotice";
import Form from "./components/Form";
import { BrandErrors, BrandRecord } from "./types";

type NewProps = {
  brand: BrandRecord;
  errors: BrandErrors;
};

export default function New({ brand, errors }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>New Brand</h1>
        </div>
      </header>

      <Form brand={brand} errors={errors} method="post" submitLabel="Create Brand" url="/brands" />
    </>
  );
}
