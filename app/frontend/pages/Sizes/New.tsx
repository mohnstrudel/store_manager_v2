import { usePage } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { SizeRecord } from "./types";

type NewProps = {
  size: SizeRecord;
};

export default function New({ size }: NewProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader className="mb-8" title="New Size" />

      <ResourceForm action="/sizes" cancelHref="/sizes" method="post" submitLabel="Create Size">
        <FormInput
          defaultValue={size.value}
          error={errors.value}
          label="Value"
          name="size[value]"
        />
      </ResourceForm>
    </>
  );
}
