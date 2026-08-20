import ResourceIndexPage from "@/components/ResourceIndexPage";

import Table from "./components/Table";
import { ShippingCompanyRecord } from "./types";

type IndexProps = {
  shippingCompanies: ShippingCompanyRecord[];
};

export default function Index({ shippingCompanies }: IndexProps) {
  return (
    <ResourceIndexPage newPath="/shipping_companies/new" title="Shipping Companies">
      <Table shippingCompanies={shippingCompanies} />
    </ResourceIndexPage>
  );
}
