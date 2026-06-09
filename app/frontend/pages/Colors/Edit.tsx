import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { ColorRecord } from "./types";

type EditProps = {
  color: ColorRecord;
};

export default function Edit({ color }: EditProps) {
  return (
    <>
      <PageHeader className="mb-8" title="Edit Color">
        <li>
          <Link href={`/colors/${color.id}`} prefetch>
            <i className="icn">📄</i>
            View Color Page
          </Link>
        </li>
      </PageHeader>
      <Form color={color} method="patch" submitLabel="Update Color" url={`/colors/${color.id}`} />
    </>
  );
}
