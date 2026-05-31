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

      <PageHeader className="mb-8" title="Edit Size">
        <li>
          <Link href={`/sizes/${size.id}`} prefetch>
            <i className="icn">📄</i>
            View Size Page
          </Link>
        </li>
      </PageHeader>

      <Form method="patch" size={size} submitLabel="Update Size" url={`/sizes/${size.id}`} />
    </>
  );
}
