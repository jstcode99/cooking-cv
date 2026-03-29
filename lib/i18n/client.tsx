"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { i18n, type Locale } from "./config";

interface I18nContextType {
  locale: Locale;
  setLocale: (locale: Locale) => void;
}

const I18nContext = createContext<I18nContextType | undefined>(undefined);

interface I18nProviderProps {
  children: ReactNode;
  locale: Locale;
}

export function I18nProvider({ children, locale }: I18nProviderProps) {
  const [currentLocale, setCurrentLocale] = useState(locale);

  useEffect(() => {
    setCurrentLocale(locale);
  }, [locale]);

  return (
    <I18nContext.Provider
      value={{
        locale: currentLocale,
        setLocale: setCurrentLocale,
      }}
    >
      {children}
    </I18nContext.Provider>
  );
}

export function useI18n() {
  const context = useContext(I18nContext);
  if (context === undefined) {
    throw new Error("useI18n must be used within an I18nProvider");
  }
  return context;
}
