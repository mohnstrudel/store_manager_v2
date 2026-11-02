import ResourceIndexPage from "@/components/ResourceIndexPage";
import type { SalesTagColor } from "@/types/salesTag";
import routes from "@/utils/routes";

import Table from "./components/Table";
import TagDetailModal from "./components/TagDetailModal";
import TagFormModal from "./components/TagFormModal";
import type { SalesTagCatalogRecord, SalesTagDetailRecord, SalesTagFormRecord } from "./types";

type IndexProps = {
  sales_tag: SalesTagFormRecord | null;
  sales_tag_detail: SalesTagDetailRecord | null;
  sales_tags: SalesTagCatalogRecord[];
  tag_colors: SalesTagColor[];
};

export default function Index({ sales_tag, sales_tag_detail, sales_tags, tag_colors }: IndexProps) {
  return (
    <>
      <ResourceIndexPage
        bordered={false}
        newOpensModal
        newPath={routes.salesTags.new.path()}
        title="Sales Tags"
      >
        <Table salesTags={sales_tags} />
      </ResourceIndexPage>

      {sales_tag ? (
        <TagFormModal colors={tag_colors} key={sales_tag.id ?? "new"} salesTag={sales_tag} />
      ) : null}
      {sales_tag_detail ? <TagDetailModal salesTag={sales_tag_detail} /> : null}
    </>
  );
}
