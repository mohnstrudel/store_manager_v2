import { usePage } from "@inertiajs/react";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { FranchiseRecord } from "./types";

type EditProps = {
  franchise: FranchiseRecord;
};

export default function Edit({ franchise }: EditProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/franchises/${franchise.id}`}>
              <i className="icn">📄</i>
              View Franchise Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Franchise"
      />

      <ResourceForm action={`/franchises/${franchise.id}`} cancelHref="/franchises" method="patch" submitLabel="Update Franchise">
        <FormField defaultValue={franchise.title} error={errors.title} label="Title" name="franchise[title]" />
      </ResourceForm>
    </>
  );
}
