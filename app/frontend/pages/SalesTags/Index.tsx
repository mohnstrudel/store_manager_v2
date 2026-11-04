import ResourceIndexPage from "@/components/ResourceIndexPage";
import type { SalesTagsIndex } from "@/types/serializers";
import routes from "@/utils/routes";

import Table from "./components/Table";
import TagDetailModal from "./components/TagDetailModal";
import TagFormModal from "./components/TagFormModal";

type IndexProps = SalesTagsIndex;

export default function Index({
  can_manage_sales_tags,
  sales_tag,
  sales_tag_detail,
  sales_tags,
  tag_colors,
}: IndexProps) {
  return (
    <>
      <ResourceIndexPage
        bordered={false}
        newOpensModal
        newPath={routes.salesTags.new.path()}
        title="Sales Tags"
      >
        <Table canManage={can_manage_sales_tags} salesTags={sales_tags} />
      </ResourceIndexPage>

      {sales_tag ? (
        <TagFormModal colors={tag_colors} key={sales_tag.id ?? "new"} salesTag={sales_tag} />
      ) : null}
      {sales_tag_detail ? <TagDetailModal salesTag={sales_tag_detail} /> : null}
    </>
  );
}
