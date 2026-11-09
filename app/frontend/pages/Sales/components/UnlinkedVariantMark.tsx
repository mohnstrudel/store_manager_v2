import { Link } from "@inertiajs/react";

import type { BrokenSalesIndex } from "@/types/serializers";
import routes from "@/utils/routes";
import { stopRowNavigation } from "@/utils/rowNavigation";

const SHOPIFY_CONFLICTS: BrokenSalesIndex["issue_type"] = "shopify_conflicts";
const TOOLTIP = "Shopify variant has no match here. Fix it in Broken Sales.";

export default function UnlinkedVariantMark() {
  return (
    <mark className="block uppercase tracking-wide text-xs w-fit mt-2 -ml-1">
      <Link
        className="link no-underline font-semibold"
        href={routes.brokenSales.index.path({ query: { issue_type: SHOPIFY_CONFLICTS } })}
        onClick={stopRowNavigation}
        title={TOOLTIP}
      >
        BROKEN
      </Link>
    </mark>
  );
}
