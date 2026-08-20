import ResourceIndexPage from "@/components/ResourceIndexPage";
import routes from "@/utils/routes";

import Table from "./components/Table";
import { BrandRecord } from "./types";

type IndexProps = {
  brands: BrandRecord[];
};

export default function Index({ brands }: IndexProps) {
  return (
    <ResourceIndexPage newPath={routes.brands.new.path()} title="Brands">
      <Table brands={brands} />
    </ResourceIndexPage>
  );
}
