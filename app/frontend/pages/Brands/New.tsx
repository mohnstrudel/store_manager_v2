import { usePage } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { BrandRecord } from "./types";

type NewProps = {
  brand: BrandRecord;
};

export default function New({ brand }: NewProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader className="mb-8" title="New Brand" />

      <ResourceForm action="/brands" cancelHref="/brands" method="post" submitLabel="Create Brand">
        <FormField
          defaultValue={brand.title}
          error={errors.title}
          label="Title"
          name="brand[title]"
        />
      </ResourceForm>
    </>
  );
}
