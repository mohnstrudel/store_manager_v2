import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import Form from "./components/Form";
import { BrandRecord } from "./types";

type NewProps = {
  brand: BrandRecord;
};

export default function New({ brand }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New Brand" />
      <Form
        brand={brand}
        method="post"
        submitLabel="Create Brand"
        url={routes.brands.create.path()}
      />
    </>
  );
}
