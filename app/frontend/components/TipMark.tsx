type TipMarkProps = {
  children: string;
  starClassName?: string;
};

export default function TipMark({ children, starClassName = "" }: TipMarkProps) {
  return (
    <span className="group relative">
      <span className={`text-yellow-600 ml-2 text-2xl/2 ${starClassName}`}>*</span>
      <span className="tip_mark__tooltip">{children}</span>
    </span>
  );
}
