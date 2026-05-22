const EMPTY_ICONS = ["👻", "👽", "💩", "🪆", "🎭"] as const;

type SearchResultsEmptyProps = {
  seed?: string;
};

export default function SearchResultsEmpty({ seed = "" }: SearchResultsEmptyProps) {
  const icon = iconForSeed(seed);

  return (
    <div className="search-results--empty flex flex-col justify-center items-center h-100">
      <i className="icn text-[180px]">{icon}</i>
      <h2 className="text-center">Nothing found</h2>
    </div>
  );
}

function iconForSeed(seed: string) {
  if (!seed) return EMPTY_ICONS[0];

  const index =
    Array.from(seed).reduce((sum, character) => sum + character.charCodeAt(0), 0) %
    EMPTY_ICONS.length;

  return EMPTY_ICONS[index];
}
