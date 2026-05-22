import ErrorNotice from "@/components/ErrorNotice";
import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { SizeRecord } from "./types";

type EditProps = {
  size: SizeRecord;
};

export default function Edit({ size }: EditProps) {
  return (
    <>
      <ErrorNotice />

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

      <Form method="patch" size={size} submitLabel="Update Size" url={`/sizes/${size.id}`} />
    </>
  );
}
