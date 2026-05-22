import { usePage } from "@inertiajs/react";

export default function ErrorNotice() {
  const { errors } = usePage().props as { errors: Record<string, string | undefined> };
  const entries = Object.entries(errors ?? {}).filter(([attribute, value]) => {
    if (attribute.includes(".") || attribute.includes("[") || attribute.includes("]")) return false;
    return !!value;
  });

  if (entries.length === 0) return null;

  return (
    <article className="h-fit mx-auto bg-red-100 rounded-xl mb-8 text-center text-red-700 lg:text-left dark:bg-red-800/60 dark:text-red-300">
      <header className="p-0 flex flex-col justify-between items-center gap-2 border-b-4 border-red-800/5 dark:border-red-950/30 lg:p-8 lg:h-24 lg:flex-row lg:gap-0">
        <i className="icn text-2xl lg:text-3xl">🚨</i>
        <p className="text-base font-semibold lg:text-lg">Fix errors and try again</p>
        <i className="icn text-2xl lg:text-3xl">🚨</i>
      </header>
      <ol className="list-decimal h-fit min-h-24 p-8 pl-16 text-left text-lg">
        {entries.map(([attribute, message]) => (
          <li className="mt-1" key={`${attribute}-${message}`}>
            <span className="font-semibold">{humanize(attribute)}</span>
            <span className="font-semibold">: </span>
            {message}
          </li>
        ))}
      </ol>
    </article>
  );
}

function humanize(value: string) {
  return value.charAt(0).toUpperCase() + value.slice(1).replace(/_/g, " ");
}
