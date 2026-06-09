import ResourceIndexPage from "@/components/ResourceIndexPage";
import Table from "./components/Table";
import { ColorRecord } from "./types";

type IndexProps = {
  colors: ColorRecord[];
};

export default function Index({ colors }: IndexProps) {
  return (
    <ResourceIndexPage newPath="/colors/new" title="Colors">
      <Table colors={colors} />
    </ResourceIndexPage>
  );
}
