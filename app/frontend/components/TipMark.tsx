type TipMarkProps = {
  children: string;
  starClassName?: string;
};

export default function TipMark({ children, starClassName = "" }: TipMarkProps) {
  return (
    <span className="group relative">
      <span className={`text-yellow-600 ml-2 text-2xl/2 ${starClassName}`}>*</span>
      <span className="cursor-text no_events absolute z-20 top-0 left-0 opacity-0 pointer-events-none transition-opacity duration-150 flex group-hover:opacity-100 group-hover:pointer-events-auto rounded-lg bg-yellow-100 dark:bg-yellow-800 border border-yellow-800/10 pt-4 pr-5 pb-5 pl-3 w-64 text-yellow-800 dark:text-yellow-100 text-sm text-pretty text-left font-normal leading-normal tracking-normal normal-case">
        {children}
      </span>
    </span>
  );
}
