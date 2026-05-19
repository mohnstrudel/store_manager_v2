import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { SizeErrors, SizeRecord } from "./types";

type EditProps = {
  errors?: SizeErrors;
  size: SizeRecord;
};

export default function Edit({ errors = {}, size }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <PageHeader
        actions={
          <li>
            <Link href={`/sizes/${size.id}`}>
              <i className="icn">📄</i>
              View Size Page
            </Link>
          </li>
        }
        className="mb-8"
        title="Edit Size"
      />

      <Form
        errors={errors}
        method="patch"
        size={size}
        submitLabel="Update Size"
        url={`/sizes/${size.id}`}
      />
    </>
  );
}
