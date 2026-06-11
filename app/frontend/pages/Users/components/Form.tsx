import { z } from "zod";
import { getFormString, zodErrorsToRecord } from "@/utils/formSchema";
import routes from "@/utils/routes";
import { msg } from "@/utils/validationMessages";
import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import ResourceForm from "@/components/ResourceForm";

export type UserFormValues = {
  id: number;
  email_address: string;
  first_name: string;
  last_name: string;
  role: string;
  path: string;
};

type UserFormProps = {
  canEditRole: boolean;
  roleOptions: [string, string][];
  user: UserFormValues;
};

const UserFormSchema = z.object({
  email_address: z.string().min(1, msg.blank).email(msg.invalid),
});

function validate(formData: FormData) {
  const result = UserFormSchema.safeParse({
    email_address: getFormString(formData, "user[email_address]"),
  });
  return result.success ? null : zodErrorsToRecord(result.error);
}

export default function Form({
  canEditRole,
  roleOptions,
  user,
}: UserFormProps) {
  return (
    <ResourceForm
      action={routes.users.update.path({ id: user.id })}
      cancelHref={routes.users.show.path({ id: user.id })}
      method="patch"
      submitLabel="Update User"
      validate={validate}
    >
      {({ errors }) => (
        <>
          <FormInput
            defaultValue={user.email_address}
            error={errors.email_address}
            label="Email"
            name="user[email_address]"
            type="email"
          />
          <FormInput
            defaultValue={user.first_name}
            error={errors.first_name}
            label="First Name"
            name="user[first_name]"
          />
          <FormInput
            defaultValue={user.last_name}
            error={errors.last_name}
            label="Last Name"
            name="user[last_name]"
          />
          {canEditRole && (
            <FormControl error={errors.role} htmlFor="user_role" label="Role">
              <select defaultValue={user.role} id="user_role" name="user[role]">
                <option value="">Select role</option>
                {roleOptions.map(([label, value]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>
            </FormControl>
          )}
        </>
      )}
    </ResourceForm>
  );
}
