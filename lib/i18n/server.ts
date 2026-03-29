import { getRequestConfig } from "next-intl/server";
import { i18n, type Locale } from "./config";

export default getRequestConfig(async ({ locale }) => {
  const validLocale: Locale = i18n.locales.includes(locale as Locale)
    ? (locale as Locale)
    : i18n.defaultLocale;

  return {
    locale: validLocale,
    messages: (await import(`@/locales/${validLocale}/auth.json`)).default,
  };
});
