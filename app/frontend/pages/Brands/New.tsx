import ErrorNotice from "@/components/ErrorNotice";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { BrandErrors, BrandRecord } from "./types";

type NewProps = {
  brand: BrandRecord;
  errors?: BrandErrors;
};

export default function New({ brand, errors = {} }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader className="mb-8" title="New Brand" />

      <Form brand={brand} errors={errors} method="post" submitLabel="Create Brand" url="/brands" />
    </>
  );
}
