import { Link } from "@inertiajs/react";

import PageHeader from "@/components/PageHeader";
import SearchableTableSection from "@/components/SearchableTableSection";
import TipMark from "@/components/TipMark";
import type { PaginationMeta } from "@/types/pagination";
import routes from "@/utils/routes";

import { formatTimestamp, stateDetails, type EmailState } from "./display";
import ProductPreview from "./ProductPreview";

type OutboundEmailRow = {
  id: number;
  recipient: string | null;
  recipient_name: string | null;
  customer_path: string | null;
  subject: string;
  product_title: string | null;
  product_thumb_url: string | null;
  sale_path: string | null;
  sale_label: string | null;
  purchase_path: string | null;
  purchase_label: string | null;
  state: EmailState;
  created_at: string;
  accepted_at: string | null;
  path: string;
};

type IndexProps = {
  outbound_emails: OutboundEmailRow[];
  pagination: PaginationMeta;
  search: { q: string };
};

export default function Index({ outbound_emails, pagination, search }: IndexProps) {
  return (
    <>
      <PageHeader
        title="Email History"
        subtitle="Search by name, email address, product, subject, or message text"
      />
      <SearchableTableSection
        hasResults={outbound_emails.length > 0}
        pagination={pagination}
        path={routes.outboundEmails.index.path()}
        query={search.q}
        resourceName="outbound_emails"
      >
        <table>
          <thead>
            <tr>
              <th>
                Email
                <TipMark
                  trigger="Status guide"
                  triggerClassName="ml-2 cursor-help text-xs font-normal text-gray-500 underline decoration-dotted dark:text-gray-400"
                >
                  <span className="tip_mark__hint">
                    {Object.values(stateDetails)
                      .map(({ label, description }) => `${label}: ${description}`)
                      .join("\n\n")}
                  </span>
                </TipMark>
              </th>
              <th>Recipient</th>
              <th>Product</th>
            </tr>
          </thead>
          <tbody>
            {outbound_emails.map((email) => (
              <tr key={email.id}>
                <td>
                  <div>
                    <Link className="link font-medium" href={email.path} prefetch>
                      {email.subject}
                    </Link>
                  </div>
                  <div className="mt-1 text-sm text-gray-600 dark:text-gray-300">
                    {stateDetails[email.state].label}
                  </div>
                  <time
                    className="block text-sm text-gray-500 dark:text-gray-400"
                    dateTime={email.accepted_at || email.created_at}
                  >
                    {formatTimestamp(email.accepted_at || email.created_at)}
                  </time>
                </td>
                <td>
                  {email.customer_path ? (
                    <Link className="link font-semibold" href={email.customer_path} prefetch>
                      {email.recipient_name || "Name not recorded"}
                    </Link>
                  ) : (
                    <strong>{email.recipient_name || "Name not recorded"}</strong>
                  )}
                  <br />
                  {email.recipient}
                </td>
                <td>
                  <ProductPreview title={email.product_title} imageUrl={email.product_thumb_url} />
                  <div className="mt-2 flex flex-wrap gap-x-3 gap-y-1 text-sm">
                    {email.sale_path && email.sale_label ? (
                      <Link className="link" href={email.sale_path} prefetch>
                        {email.sale_label}
                      </Link>
                    ) : null}
                    {email.purchase_path && email.purchase_label ? (
                      <Link className="link" href={email.purchase_path} prefetch>
                        {email.purchase_label}
                      </Link>
                    ) : null}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </SearchableTableSection>
      {pagination.total_count === 0 && !search.q ? (
        <p className="mt-4">No emails to show yet.</p>
      ) : null}
    </>
  );
}
