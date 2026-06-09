import ResourceIndexPage from "@/components/ResourceIndexPage";
import Table from "./components/Table";
import { BrandRecord } from "./types";

type IndexProps = {
  brands: BrandRecord[];
};

export default function Index({ brands }: IndexProps) {
  return (
    <ResourceIndexPage newPath="/brands/new" title="Brands">
      <Table brands={brands} />
    </ResourceIndexPage>
  );
}
