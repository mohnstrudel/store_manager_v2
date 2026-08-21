type AmountProps = {
  value: string | null;
  emphasizeSign?: boolean;
};

const MINUS_SIGN = "−";

export default function Amount({ value, emphasizeSign = false }: AmountProps) {
  if (!value) return null;

  return (
    <span className="amount" data-tone={amountTone(value, emphasizeSign)}>
      {typographicAmount(value)}
    </span>
  );
}

export function isNegativeAmount(value: string | null): boolean {
  return value?.startsWith("-") ?? false;
}

function amountTone(value: string, emphasizeSign: boolean): "negative" | "positive" | undefined {
  if (isNegativeAmount(value)) return "negative";
  if (emphasizeSign) return "positive";

  return undefined;
}

function typographicAmount(value: string): string {
  return isNegativeAmount(value) ? MINUS_SIGN + value.slice(1) : value;
}
