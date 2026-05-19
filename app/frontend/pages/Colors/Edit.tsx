import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { ColorErrors, ColorRecord } from "./types";

type EditProps = {
  color: ColorRecord;
  errors?: ColorErrors;
};

export default function Edit({ color, errors = {} }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

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

      <Form
        color={color}
        errors={errors}
        method="patch"
        submitLabel="Update Color"
        url={`/colors/${color.id}`}
      />
    </>
  );
}
