type PurchasedSoldRatioProps = {
  purchased: number;
  sold: number;
};

export default function PurchasedSoldRatio({ purchased, sold }: PurchasedSoldRatioProps) {
  const ratio = `${purchased}\u2009/\u2009${sold}`;
  const markClass = purchased >= sold ? "mark-gray mr-1.5" : "mr-1.5";

  return <mark className={markClass}>{ratio}</mark>;
}
