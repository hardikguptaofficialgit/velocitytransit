/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#141414",
        secondary: "#2A2A2A",
        accent: "#4A90E2",
      },
      fontFamily: {
        sans: ['"Space Grotesk"', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
