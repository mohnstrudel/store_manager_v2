import Link from "@/components/Link";
import Form from "./components/Form";
import ErrorNotice from "@/components/ErrorNotice";
import { SizeErrors, SizeRecord } from "./types";

type EditProps = {
  errors: SizeErrors;
  size: SizeRecord;
};

export default function Edit({ errors, size }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>Edit Size</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/sizes/${size.id}`}>
              <i className="icn">📄</i>
              View Size Page
            </Link>
          </li>
        </menu>
      </header>

      <Form errors={errors} method="patch" size={size} submitLabel="Update Size" url={`/sizes/${size.id}`} />
    </>
  );
}
