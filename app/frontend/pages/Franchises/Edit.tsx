import { usePage, Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";
import { FranchiseRecord } from "./types";

type EditProps = {
  franchise: FranchiseRecord;
};

export default function Edit({ franchise }: EditProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader className="mb-8" title="Edit Franchise">
        <li>
          <Link href={`/franchises/${franchise.id}`} prefetch>
            <i className="icn">📄</i>
            View Franchise Page
          </Link>
        </li>
      </PageHeader>

      <ResourceForm
        action={`/franchises/${franchise.id}`}
        cancelHref="/franchises"
        method="patch"
        submitLabel="Update Franchise"
      >
        <FormInput
          defaultValue={franchise.title}
          error={errors.title}
          label="Title"
          name="franchise[title]"
        />
      </ResourceForm>
    </>
  );
}
