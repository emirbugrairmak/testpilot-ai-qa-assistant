/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      /* ── Marka Renkleri (proje.md'den) ── */
      colors: {
        navy: {
          DEFAULT: "#102050",
          50: "#e8ecf5",
          100: "#c5cfe6",
          200: "#9eaed4",
          300: "#778dc2",
          400: "#5974b5",
          500: "#3b5ba8",
          600: "#2d4a8a",
          700: "#1f396c",
          800: "#102050",
          900: "#081030",
        },
        sky: {
          DEFAULT: "#50B0E0",
          50: "#eaf6fc",
          100: "#c5e8f7",
          200: "#9dd9f1",
          300: "#74c9eb",
          400: "#50B0E0",
          500: "#3096c9",
          600: "#2278a3",
          700: "#195a7c",
          800: "#103c55",
          900: "#081e2e",
        },
        accent: {
          DEFAULT: "#E07020",
          50: "#fdf1e7",
          100: "#f9d9be",
          200: "#f4bf93",
          300: "#efa567",
          400: "#ea8a3c",
          500: "#E07020",
          600: "#b85a1a",
          700: "#904514",
          800: "#68300e",
          900: "#401b08",
        },
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};
