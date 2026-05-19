import ErrorNotice from "@/components/ErrorNotice";
import Link from "@/components/Link";
import Form from "./components/Form";
import { ColorErrors, ColorRecord } from "./types";

type EditProps = {
  color: ColorRecord;
  errors: ColorErrors;
};

export default function Edit({ color, errors }: EditProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>Edit Color</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={`/colors/${color.id}`}>
              <i className="icn">📄</i>
              View Color Page
            </Link>
          </li>
        </menu>
      </header>

      <Form color={color} errors={errors} method="patch" submitLabel="Update Color" url={`/colors/${color.id}`} />
    </>
  );
}
