import { useCallback, useMemo, type ChangeEvent, type FormEvent, useState } from "react";
import { router, Link } from "@inertiajs/react";

type SearchBarProps = {
  initialQuery: string;
  path: string;
  resourceName: string;
};

export default function SearchBar({ initialQuery, path, resourceName }: SearchBarProps) {
  const [query, setQuery] = useState(initialQuery);
  const reloadOnly = useMemo(() => [resourceName, "pagination", "search"], [resourceName]);

  const handleSubmit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      router.get(path, { q: query || undefined }, { only: reloadOnly, preserveState: true });
    },
    [path, query, reloadOnly],
  );

  const handleChange = useCallback((e: ChangeEvent<HTMLInputElement>) => {
    setQuery(e.target.value);
  }, []);

  return (
    <form
      className="flex flex-col lg:flex-row lg:items-center w-full max-w-full lg:max-w-2/3"
      onSubmit={handleSubmit}
    >
      <input
        className={initialQuery ? "border-2" : "border"}
        name="q"
        onChange={handleChange}
        placeholder="Find what you need..."
        type="search"
        value={query}
      />
      <button className="mt-2 lg:mt-0 lg:ml-2 btn_rounded" type="submit">
        <i className="icn">🔎</i>
        Search
      </button>
      {initialQuery && (
        <Link className="mt-2 lg:mt-0 lg:ml-2 btn_rounded btn_red" href={path} prefetch>
          <i className="icn">❎</i>
          Exit
        </Link>
      )}
    </form>
  );
}
