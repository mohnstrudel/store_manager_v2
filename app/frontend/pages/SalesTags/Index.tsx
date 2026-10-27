import PageHeader from "@/components/PageHeader";
import SearchBar from "@/components/SearchBar";
import type { SalesTagColor } from "@/types/salesTag";
import routes from "@/utils/routes";

import { TagBadge } from "../Sales/components/TagBadges";
import NewTagForm from "./components/NewTagForm";
import type { SalesTagCatalogRecord } from "./types";

type IndexProps = {
  sales_tags: SalesTagCatalogRecord[];
  search: { q: string };
  tag_colors: SalesTagColor[];
};

export default function Index({ sales_tags, search, tag_colors }: IndexProps) {
  return (
    <>
      <PageHeader title="Sales Tags" />
      <section className="section_border_base section_wide">
        <NewTagForm query={search.q} tagColors={tag_colors} />
        <div className="page_search">
          <SearchBar
            initialQuery={search.q}
            path={routes.salesTags.index.path()}
            resourceName="sales_tags"
          />
        </div>
        <Catalog query={search.q} salesTags={sales_tags} />
      </section>
    </>
  );
}

function Catalog({ query, salesTags }: { query: string; salesTags: SalesTagCatalogRecord[] }) {
  if (salesTags.length === 0) {
    return (
      <p className="px-4 lg:px-8 pb-6">
        {query ? `No sales tags match “${query}”.` : "No sales tags yet. Add the first one above."}
      </p>
    );
  }

  return (
    <div className="px-2 lg:px-5">
      <table>
        <thead>
          <tr>
            <th>Tag</th>
            <th className="text-right">Sales</th>
          </tr>
        </thead>
        <tbody>
          {salesTags.map((tag) => (
            <tr key={tag.id}>
              <td>
                <TagBadge color={tag.color}>{tag.name}</TagBadge>
              </td>
              <td className="text-right">{tag.usage_count}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
