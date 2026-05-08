const leadingMarkersPattern = /^\s*(?:(?:[-*•]\s+)|(?:\d+[\.)]\s+))+/;
const orderedLinePattern = /^(\s*\d+[\.)]\s+)(.+)$/;
const bulletLinePattern = /^(\s*[-*]\s+)(.+)$/;

export function cleanListItem(value: unknown) {
  let text = String(value ?? "").replace(/\s+/g, " ").trim();
  let previous: string | null = null;

  while (previous !== text) {
    previous = text;
    text = text.replace(leadingMarkersPattern, "").trim();
  }

  return text;
}

export function cleanMarkdownListMarkers(content: string) {
  return String(content ?? "")
    .split("\n")
    .map((line) => {
      const ordered = line.match(orderedLinePattern);
      if (ordered) {
        return `${ordered[1]}${cleanListItem(ordered[2])}`;
      }

      const bullet = line.match(bulletLinePattern);
      if (bullet) {
        return `${bullet[1]}${cleanListItem(bullet[2])}`;
      }

      return line;
    })
    .join("\n");
}
