/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,js}"],
  theme: {
    extend: {
      colors: {
        "deep-twilight": {
          50: "rgb(var(--color-deep-twilight-50) / <alpha-value>)",
          100: "rgb(var(--color-deep-twilight-100) / <alpha-value>)",
          200: "rgb(var(--color-deep-twilight-200) / <alpha-value>)",
          300: "rgb(var(--color-deep-twilight-300) / <alpha-value>)",
          400: "rgb(var(--color-deep-twilight-400) / <alpha-value>)",
          500: "rgb(var(--color-deep-twilight-500) / <alpha-value>)",
          600: "rgb(var(--color-deep-twilight-600) / <alpha-value>)",
          700: "rgb(var(--color-deep-twilight-700) / <alpha-value>)",
          800: "rgb(var(--color-deep-twilight-800) / <alpha-value>)",
          900: "rgb(var(--color-deep-twilight-900) / <alpha-value>)",
          950: "rgb(var(--color-deep-twilight-950) / <alpha-value>)",
        },
        cerulean: {
          50: "rgb(var(--color-cerulean-50) / <alpha-value>)",
          100: "rgb(var(--color-cerulean-100) / <alpha-value>)",
          200: "rgb(var(--color-cerulean-200) / <alpha-value>)",
          300: "rgb(var(--color-cerulean-300) / <alpha-value>)",
          400: "rgb(var(--color-cerulean-400) / <alpha-value>)",
          500: "rgb(var(--color-cerulean-500) / <alpha-value>)",
          600: "rgb(var(--color-cerulean-600) / <alpha-value>)",
          700: "rgb(var(--color-cerulean-700) / <alpha-value>)",
          800: "rgb(var(--color-cerulean-800) / <alpha-value>)",
          900: "rgb(var(--color-cerulean-900) / <alpha-value>)",
          950: "rgb(var(--color-cerulean-950) / <alpha-value>)",
        },
        "sky-surge": {
          50: "rgb(var(--color-sky-surge-50) / <alpha-value>)",
          100: "rgb(var(--color-sky-surge-100) / <alpha-value>)",
          200: "rgb(var(--color-sky-surge-200) / <alpha-value>)",
          300: "rgb(var(--color-sky-surge-300) / <alpha-value>)",
          400: "rgb(var(--color-sky-surge-400) / <alpha-value>)",
          500: "rgb(var(--color-sky-surge-500) / <alpha-value>)",
          600: "rgb(var(--color-sky-surge-600) / <alpha-value>)",
          700: "rgb(var(--color-sky-surge-700) / <alpha-value>)",
          800: "rgb(var(--color-sky-surge-800) / <alpha-value>)",
          900: "rgb(var(--color-sky-surge-900) / <alpha-value>)",
          950: "rgb(var(--color-sky-surge-950) / <alpha-value>)",
        },
      },
    },
  },
};
