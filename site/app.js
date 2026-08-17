const state = { data: null, color: "blue", mode: "light" };

const byId = (id) => document.getElementById(id);
const capitalize = (value) => value.charAt(0).toUpperCase() + value.slice(1);

function currentTheme() {
  return state.data.themes.find((theme) => theme.color === state.color && theme.mode === state.mode);
}

function applyTheme() {
  const theme = currentTheme();
  if (!theme) return;

  const root = document.documentElement;
  Object.entries(theme.neutrals).forEach(([role, value]) => root.style.setProperty(`--${role.replaceAll("_", "-")}`, value));
  Object.entries(theme.accent).forEach(([role, value]) => {
    const property = ["strong", "secondary", "faint", "wash"].includes(role) ? `--accent-${role}` : `--${role === "primary" ? "accent" : role.replaceAll("_", "-")}`;
    root.style.setProperty(property, value);
  });
  const syntaxDefaults = {
    keyword: theme.accent.primary,
    type: theme.accent.secondary,
    function: theme.neutrals.fg,
    variable: theme.neutrals.fg,
    string: theme.neutrals.fg,
    constant: theme.neutrals.fg,
    number: theme.neutrals.fg,
    symbol: theme.neutrals.fg,
    attribute: theme.accent.primary,
    operator: theme.neutrals.secondary,
    punctuation: theme.neutrals.secondary
  };
  Object.entries(syntaxDefaults).forEach(([role, fallback]) => {
    root.style.setProperty(`--syntax-${role}`, theme.syntax[role] || fallback);
  });
  root.style.colorScheme = state.mode;
  document.querySelector('meta[name="theme-color"]').content = theme.neutrals.bg;

  document.querySelectorAll("[data-color]").forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.color === state.color)));
  document.querySelectorAll("[data-mode]").forEach((button) => button.setAttribute("aria-pressed", String(button.dataset.mode === state.mode)));
  byId("download-theme").textContent = `Air ${capitalize(state.color)}`;
  byId("status-color").textContent = capitalize(state.color);
  byId("footer-color").textContent = capitalize(state.color);
  byId("footer-mode").textContent = capitalize(state.mode);
  renderPalette(theme);
}

function renderColorOptions() {
  const colors = [...new Set(state.data.themes.map((theme) => theme.color))];
  const container = byId("color-options");
  container.replaceChildren(...colors.map((color) => {
    const reference = state.data.themes.find((theme) => theme.color === color && theme.mode === state.mode) || state.data.themes.find((theme) => theme.color === color);
    const button = document.createElement("button");
    button.type = "button";
    button.className = "color-option";
    button.dataset.color = color;
    button.setAttribute("aria-label", capitalize(color));
    button.setAttribute("aria-pressed", String(color === state.color));
    button.style.setProperty("--swatch", reference.accent.primary);
    const spectrum = ["red", "orange", "yellow", "green", "cyan", "blue", "violet"]
      .map((role) => reference.spectrum[role])
      .filter(Boolean);
    if (spectrum.length > 1) button.style.setProperty("--swatch-fill", `conic-gradient(${spectrum.join(", ")})`);
    button.addEventListener("click", () => { state.color = color; applyTheme(); });
    return button;
  }));
}

function readableText(hex) {
  const components = hex.slice(1).match(/../g).map((part) => parseInt(part, 16) / 255);
  const lightness = (0.2126 * components[0]) + (0.7152 * components[1]) + (0.0722 * components[2]);
  return lightness > 0.55 ? "#25272A" : "#FAFAF9";
}

function renderPalette(theme) {
  const landmarkRoles = new Set(["keyword", "type", "function", "string", "constant", "number", "attribute"]);
  const landmarks = Object.entries(theme.syntax).filter(([role]) => landmarkRoles.has(role));
  const authoredColors = Object.keys(theme.spectrum).length > 0
    ? Object.entries(theme.spectrum).map(([key, value]) => [`spectrum ${key}`, value])
    : landmarks.map(([key, value]) => [`syntax ${key}`, value]);
  const roles = {
    ...theme.neutrals,
    ...Object.fromEntries(Object.entries(theme.accent).map(([key, value]) => [`accent ${key}`, value])),
    ...Object.fromEntries(authoredColors)
  };
  byId("palette-grid").replaceChildren(...Object.entries(roles).map(([role, value]) => {
    const card = document.createElement("article");
    card.className = "swatch-card";
    card.style.setProperty("--swatch", value);
    card.style.setProperty("--swatch-text", readableText(value));
    const label = document.createElement("span");
    label.textContent = role.replaceAll("_", " ");
    const code = document.createElement("code");
    code.textContent = value;
    card.append(label, code);
    return card;
  }));
}

function renderTargets() {
  const available = state.data.targets.filter((target) => target.status === "available");
  byId("available-count").textContent = available.length;
  byId("target-grid").replaceChildren(...state.data.targets.map((target) => {
    const card = document.createElement("article");
    card.className = `target-card ${target.status}`;
    const title = document.createElement("h3");
    title.textContent = target.name;
    const detail = document.createElement("p");
    detail.textContent = target.description || "Generated theme adapter.";
    const status = document.createElement("span");
    status.className = "status";
    status.textContent = target.kind;
    card.append(title, detail, status);
    return card;
  }));
}

async function start() {
  const response = await fetch("themes.json");
  if (!response.ok) throw new Error(`Could not load themes.json (${response.status})`);
  state.data = await response.json();
  state.mode = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  if (!state.data.themes.some((theme) => theme.color === state.color)) state.color = state.data.themes[0]?.color;
  if (!state.data.themes.some((theme) => theme.mode === state.mode)) state.mode = state.data.themes[0]?.mode;
  byId("repository-link").href = state.data.repository;
  byId("download-link").href = state.data.release;
  renderColorOptions();
  renderTargets();
  document.querySelectorAll("[data-mode]").forEach((button) => button.addEventListener("click", () => {
    state.mode = button.dataset.mode;
    renderColorOptions();
    applyTheme();
  }));
  applyTheme();
}

start().catch((error) => {
  console.error(error);
  byId("color-options").textContent = "Theme data unavailable";
});
