import { usePage } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { FranchiseRecord } from "./types";

type NewProps = {
  franchise: FranchiseRecord;
};

export default function New({ franchise }: NewProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader className="mb-8" title="New Franchise" />

      <ResourceForm action="/franchises" cancelHref="/franchises" method="post" submitLabel="Create Franchise">
        <FormField defaultValue={franchise.title} error={errors.title} label="Title" name="franchise[title]" />
      </ResourceForm>
    </>
  );
}
