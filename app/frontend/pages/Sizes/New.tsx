import ErrorNotice from "./components/ErrorNotice";
import Form from "./components/Form";
import { SizeErrors, SizeRecord } from "./types";

type NewProps = {
  errors: SizeErrors;
  size: SizeRecord;
};

export default function New({ errors, size }: NewProps) {
  return (
    <>
      <ErrorNotice errors={errors} />

      <header className="nav_header mb-8">
        <div className="flex gap-4">
          <h1>New Size</h1>
        </div>
      </header>

      <Form errors={errors} method="post" size={size} submitLabel="Create Size" url="/sizes" />
    </>
  );
}
