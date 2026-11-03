import {
  AlienIcon,
  GhostIcon,
  NestingDollsIcon,
  PerformingArtsIcon,
  PoopIcon,
} from "./EmptyStateIcons";

const EMPTY_ICONS = [
  <GhostIcon className="size-44" key="ghost" />,
  <AlienIcon className="size-44" key="alien" />,
  <PoopIcon className="size-44" key="poop" />,
  <NestingDollsIcon className="size-44" key="nesting-dolls" />,
  <PerformingArtsIcon className="size-44" key="performing-arts" />,
] as const;

type SearchResultsEmptyProps = {
  seed?: string;
};

export default function SearchResultsEmpty({ seed = "" }: SearchResultsEmptyProps) {
  return (
    <div className="search_results_empty flex flex-col justify-center items-center h-100">
      {iconForSeed(seed)}
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
