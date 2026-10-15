import { Link } from "@inertiajs/react";

import Field from "@/components/Field";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import { formatTimestamp, stateDetails, type EmailState } from "./display";
import ProductPreview from "./ProductPreview";

type OutboundEmailRecord = {
  id: number;
  recipient: string | null;
  recipient_name: string | null;
  sender: string | null;
  subject: string;
  body: string | null;
  product_title: string | null;
  product_thumb_url: string | null;
  state: EmailState;
  attempts: number;
  last_attempt_at: string | null;
  last_error: string | null;
  accepted_at: string | null;
  created_at: string;
};

export default function Show({ outbound_email: email }: { outbound_email: OutboundEmailRecord }) {
  return (
    <>
      <PageHeader title={email.subject}>
        <li>
          <Link href={routes.outboundEmails.index.path()} prefetch>
            Email History
          </Link>
        </li>
      </PageHeader>
      <div className="section_wide mt-8 flex flex-col gap-8">
        <div className="cards items-start">
          <dl className="card min-w-0 grow lg:basis-0">
            <Field label="Recipient" value={email.recipient_name || "Name not recorded"} />
            <Field label="Email address" value={email.recipient ?? "Not recorded"} />
            <dt>Product</dt>
            <dd>
              <ProductPreview title={email.product_title} imageUrl={email.product_thumb_url} />
            </dd>
          </dl>
          <dl className="card min-w-0 grow lg:basis-0">
            <Field label="Status" value={stateDetails[email.state].label}>
              {stateDetails[email.state].label}
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {stateDetails[email.state].description}
              </p>
            </Field>
            <Field label="Recorded" value={formatTimestamp(email.created_at)} />
            <Field label="Sending attempts" value={email.attempts} />
            <Field
              label="Last send attempt"
              value={email.last_attempt_at && formatTimestamp(email.last_attempt_at)}
            />
            <Field
              label="Handed to email service"
              value={email.accepted_at && formatTimestamp(email.accepted_at)}
            />
            {email.last_error ? (
              <Field label="Last sending error" value={email.last_error}>
                <span className="whitespace-pre-wrap break-words">{email.last_error}</span>
              </Field>
            ) : null}
          </dl>
        </div>

        <section
          aria-label="Email preview"
          className="max-w-4xl overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900"
        >
          <header className="px-5 py-5 sm:px-8">
            <p className="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
              Email preview
            </p>
            <h2 className="mt-3 text-xl font-semibold">{email.subject}</h2>
            <dl className="mt-5 grid gap-x-4 gap-y-2 text-sm sm:grid-cols-[max-content_1fr]">
              <dt className="text-gray-500 dark:text-gray-400">From</dt>
              <dd className="break-all">{email.sender ?? "Not recorded"}</dd>
              <dt className="text-gray-500 dark:text-gray-400">To</dt>
              <dd className="break-all">
                {email.recipient_name && email.recipient
                  ? `${email.recipient_name} <${email.recipient}>`
                  : (email.recipient_name ?? email.recipient ?? "Not recorded")}
              </dd>
              <dt className="text-gray-500 dark:text-gray-400">Recorded</dt>
              <dd>{formatTimestamp(email.created_at)}</dd>
            </dl>
          </header>
          <div className="min-h-48 border-t border-gray-200 px-5 py-6 leading-relaxed dark:border-gray-700 sm:px-8">
            {email.body ? (
              <div className="whitespace-pre-wrap break-words">{email.body}</div>
            ) : (
              <p className="text-gray-500 dark:text-gray-400">Email text was not recorded.</p>
            )}
          </div>
        </section>
      </div>
    </>
  );
}
