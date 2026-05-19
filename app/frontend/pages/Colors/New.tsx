import ErrorNotice from "@/components/ErrorNotice";
import Form from "./components/Form";
import { ColorErrors, ColorRecord } from "./types";

type NewProps = {
  color: ColorRecord;
  errors: ColorErrors;
};

export default function New({ color, errors }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>New Color</h1>
        </div>
      </header>

      <Form color={color} errors={errors} method="post" submitLabel="Create Color" url="/colors" />
    </>
  );
}
