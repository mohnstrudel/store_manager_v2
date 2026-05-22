import { usePage, Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import FormField from "@/components/FormField";
import ResourceForm from "@/components/ResourceForm";
import { ColorRecord } from "./types";

type EditProps = {
  color: ColorRecord;
};

export default function Edit({ color }: EditProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <PageHeader
        actions={
          <li>
            <Link href={`/colors/${color.id}`}>
              <i className="icn">📄</i>
              View Color Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Color"
      />

      <ResourceForm
        action={`/colors/${color.id}`}
        cancelHref="/colors"
        method="patch"
        submitLabel="Update Color"
      >
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
