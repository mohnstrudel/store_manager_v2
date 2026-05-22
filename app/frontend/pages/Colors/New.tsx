import { usePage } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { ColorRecord } from "./types";

type NewProps = {
  color: ColorRecord;
};

export default function New({ color }: NewProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader className="mb-8" title="New Color" />

      <ResourceForm action="/colors" cancelHref="/colors" method="post" submitLabel="Create Color">
        <FormField
          defaultValue={color.value}
          error={errors.value}
          label="Value"
          name="color[value]"
        />
      </ResourceForm>
    </>
  );
}
