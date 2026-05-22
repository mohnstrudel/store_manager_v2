import { usePage, Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { BrandRecord } from "./types";

type EditProps = {
  brand: BrandRecord;
};

export default function Edit({ brand }: EditProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/brands/${brand.id}`}>
              <i className="icn">📄</i>
              View Brand Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Brand"
      />

      <ResourceForm
        action={`/brands/${brand.id}`}
        cancelHref="/brands"
        method="patch"
        submitLabel="Update Brand"
      >
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
