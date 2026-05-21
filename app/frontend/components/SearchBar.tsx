import { type FormEvent, useState } from "react";
import { router } from "@inertiajs/react";
import Link from "@/components/Link";

type SearchBarProps = {
  initialQuery: string;
  path: string;
  reloadOnly: string[];
};

export default function SearchBar({ initialQuery, path, reloadOnly }: SearchBarProps) {
  const [query, setQuery] = useState(initialQuery);

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    router.get(
      path,
      { q: query || undefined },
      { only: reloadOnly, preserveState: true },
    );
  }

  return (
    <form
      className="flex flex-col lg:flex-row lg:items-center w-full max-w-full lg:max-w-2/3"
      onSubmit={handleSubmit}
    >
      <input
        className={initialQuery ? "border-2" : "border"}
        name="q"
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Find what you need..."
        type="search"
        value={query}
      />
      <button className="mt-2 lg:mt-0 lg:ml-2 btn-rounded" type="submit">
        <i className="icn">🔎</i>
        Search
      </button>
      {initialQuery && (
        <Link className="mt-2 lg:mt-0 lg:ml-2 btn-rounded btn-red" href={path}>
          <i className="icn">❎</i>
          Exit
        </Link>
      )}
    </form>
  );
}
