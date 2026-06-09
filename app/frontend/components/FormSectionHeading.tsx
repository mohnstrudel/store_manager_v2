type FormSectionHeadingProps = {
  subtitle?: string;
  title: string;
};

export default function FormSectionHeading({ subtitle, title }: FormSectionHeadingProps) {
  return (
    <header>
      <h2 className="label">{title}</h2>
      {subtitle && <p className="text-gray-600 dark:text-gray-500 mb-4">{subtitle}</p>}
    </header>
  );
}
